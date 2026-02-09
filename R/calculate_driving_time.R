#' Calculate Driving Time Between Coordinates
#'
#' Calculate driving times and distances between origin and destination coordinates
#' using the Google Maps Distance Matrix API. Supports different travel modes,
#' traffic conditions, and batch processing.
#'
#' @param data A data frame containing origin and destination coordinates
#' @param origin_lat Column name for origin latitude (default: "origin_lat")
#' @param origin_lon Column name for origin longitude (default: "origin_lon")
#' @param dest_lat Column name for destination latitude (default: "dest_lat")
#' @param dest_lon Column name for destination longitude (default: "dest_lon")
#' @param api_key Google Maps API key. If NULL, will look for GOOGLE_MAPS_API_KEY
#'   environment variable
#' @param delay_seconds Delay between API calls in seconds to avoid rate limits
#'   (default: 0.1)
#' @param mode Travel mode: "driving", "walking", "bicycling", or "transit"
#'   (default: "driving")
#' @param departure_time Departure time for the trip. Can be:
#'   \itemize{
#'     \item NULL (default): no specific time, returns typical duration
#'     \item "now": current time with live traffic
#'     \item POSIXct datetime object: specific future time
#'     \item Character string in format "YYYY-MM-DD HH:MM:SS"
#'   }
#' @param traffic_model Traffic model to use when departure_time is set:
#'   "best_guess", "pessimistic", or "optimistic" (default: "best_guess")
#'
#' @return Data frame with original data plus three new columns:
#'   \itemize{
#'     \item driving_time_min: Travel time in minutes
#'     \item distance_km: Distance in kilometers
#'     \item api_status: API response status ("OK" for success)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' data <- data.frame(
#'   origin_lat = c(40.7128, 34.0522),
#'   origin_lon = c(-74.0060, -118.2437),
#'   dest_lat = c(42.3601, 37.7749),
#'   dest_lon = c(-71.0589, -122.4194)
#' )
#' 
#' # Set API key first
#' set_api_key("YOUR_API_KEY")
#' 
#' # Calculate driving times
#' results <- calculate_driving_time(data)
#' 
#' # With current traffic
#' results <- calculate_driving_time(data, departure_time = "now")
#' 
#' # For specific future time
#' results <- calculate_driving_time(data, 
#'                                   departure_time = "2024-03-15 08:00:00")
#' 
#' # With custom column names
#' results <- calculate_driving_time(data,
#'                                   origin_lat = "lat_HS",
#'                                   origin_lon = "lon_HS",
#'                                   dest_lat = "lat_coll",
#'                                   dest_lon = "lon_coll")
#' }
calculate_driving_time <- function(data,
                                   origin_lat = "origin_lat",
                                   origin_lon = "origin_lon",
                                   dest_lat = "dest_lat",
                                   dest_lon = "dest_lon",
                                   api_key = NULL,
                                   delay_seconds = 0.1,
                                   mode = "driving",
                                   departure_time = NULL,
                                   traffic_model = "best_guess") {
  
  # Check if required packages are installed
  if (!requireNamespace("googleway", quietly = TRUE)) {
    stop("Package 'googleway' is required. Install it with: install.packages('googleway')")
  }
  
  # Get API key from environment if not provided
  if (is.null(api_key)) {
    api_key <- Sys.getenv("GOOGLE_MAPS_API_KEY")
    if (api_key == "") {
      stop("API key not provided. Set it with set_api_key() or provide via api_key parameter.")
    }
  }
  
  # Validate column names
  required_cols <- c(origin_lat, origin_lon, dest_lat, dest_lon)
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop("Missing columns in data: ", paste(missing_cols, collapse = ", "))
  }
  
  # Validate mode
  valid_modes <- c("driving", "walking", "bicycling", "transit")
  if (!mode %in% valid_modes) {
    stop("Invalid mode. Choose from: ", paste(valid_modes, collapse = ", "))
  }
  
  # Validate and process departure_time
  departure_timestamp <- NULL
  if (!is.null(departure_time)) {
    if (mode != "driving" && mode != "transit") {
      warning("departure_time is only supported for 'driving' and 'transit' modes. Ignoring departure_time.")
      departure_time <- NULL
    } else {
      departure_timestamp <- process_departure_time(departure_time)
    }
  }
  
  # Validate traffic_model
  valid_traffic_models <- c("best_guess", "pessimistic", "optimistic")
  if (!traffic_model %in% valid_traffic_models) {
    stop("Invalid traffic_model. Choose from: ", paste(valid_traffic_models, collapse = ", "))
  }
  
  # Progress messages
  if (!is.null(departure_time)) {
    cat("Calculating driving times for", nrow(data), "routes with departure time settings...\n")
    if (is.character(departure_time) && tolower(departure_time) == "now") {
      cat("Using current traffic conditions\n")
    } else {
      cat("Using traffic predictions for:", format(as.POSIXct(departure_timestamp, origin = "1970-01-01"), "%Y-%m-%d %H:%M:%S"), "\n")
    }
    cat("Traffic model:", traffic_model, "\n\n")
  } else {
    cat("Calculating driving times for", nrow(data), "routes...\n")
  }
  cat("This may take a while. Please be patient.\n\n")
  
  # Initialize result columns
  data$driving_time_min <- NA
  data$distance_km <- NA
  data$api_status <- NA
  
  # Process each row
  for (i in 1:nrow(data)) {
    if (i %% 10 == 0) {
      cat("Processing route", i, "of", nrow(data), "\n")
    }
    
    result <- get_single_route(
      origin_lat = data[[origin_lat]][i],
      origin_lon = data[[origin_lon]][i],
      dest_lat = data[[dest_lat]][i],
      dest_lon = data[[dest_lon]][i],
      api_key = api_key,
      mode = mode,
      departure_time = departure_timestamp,
      traffic_model = traffic_model
    )
    
    data$driving_time_min[i] <- result$duration_minutes
    data$distance_km[i] <- result$distance_km
    data$api_status[i] <- result$status
    
    # Add delay to avoid rate limits
    if (i < nrow(data)) {
      Sys.sleep(delay_seconds)
    }
  }
  
  cat("\nComplete! Processed", nrow(data), "routes.\n")
  cat("Successful:", sum(data$api_status == "OK"), "\n")
  cat("Failed:", sum(data$api_status != "OK"), "\n")
  
  return(data)
}
