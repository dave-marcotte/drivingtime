#' Get driving time for a single route (internal function)
#' @keywords internal
get_single_route <- function(origin_lat, origin_lon, dest_lat, dest_lon, api_key, 
                             mode = "driving", departure_time = NULL, 
                             traffic_model = "best_guess") {
  tryCatch({
    origin <- paste0(origin_lat, ",", origin_lon)
    destination <- paste0(dest_lat, ",", dest_lon)
    
    # Build API call parameters
    api_params <- list(
      origins = origin,
      destinations = destination,
      key = api_key,
      mode = mode
    )
    
    # Add departure_time if provided
    if (!is.null(departure_time)) {
      api_params$departure_time <- departure_time
      api_params$traffic_model <- traffic_model
    }
    
    result <- do.call(googleway::google_distance, api_params)
    
    # Extract results
    duration_sec <- result$rows$elements[[1]]$duration$value
    duration_min <- duration_sec / 60
    distance_m <- result$rows$elements[[1]]$distance$value
    distance_km <- distance_m / 1000
    status <- result$rows$elements[[1]]$status
    
    return(list(
      duration_minutes = duration_min,
      distance_km = distance_km,
      status = status
    ))
    
  }, error = function(e) {
    return(list(
      duration_minutes = NA,
      distance_km = NA,
      status = paste("Error:", e$message)
    ))
  })
}

#' Process departure time into Unix timestamp
#' @keywords internal
process_departure_time <- function(departure_time) {
  if (is.null(departure_time)) {
    return(NULL)
  }
  
  # Handle "now"
  if (is.character(departure_time) && tolower(departure_time) == "now") {
    return(as.integer(Sys.time()))
  }
  
  # Handle POSIXct
  if (inherits(departure_time, "POSIXct") || inherits(departure_time, "POSIXt")) {
    return(as.integer(departure_time))
  }
  
  # Handle character datetime string
  if (is.character(departure_time)) {
    tryCatch({
      dt <- as.POSIXct(departure_time, tz = "UTC")
      if (is.na(dt)) {
        stop("Could not parse departure_time. Use format: 'YYYY-MM-DD HH:MM:SS'")
      }
      # Check if time is in the past
      if (dt < Sys.time()) {
        warning("Departure time is in the past. Using current time instead.")
        return(as.integer(Sys.time()))
      }
      return(as.integer(dt))
    }, error = function(e) {
      stop("Could not parse departure_time. Use format: 'YYYY-MM-DD HH:MM:SS' or 'now'")
    })
  }
  
  # Handle numeric (assume Unix timestamp)
  if (is.numeric(departure_time)) {
    return(as.integer(departure_time))
  }
  
  stop("Invalid departure_time format. Use 'now', POSIXct object, or 'YYYY-MM-DD HH:MM:SS' string")
}
