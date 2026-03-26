#' Calculate Driving Time Between Coordinates
#'
#' Calculate driving times and distances between origin and destination
#' coordinates using the Google Maps Distance Matrix API. Supports different
#' travel modes, traffic conditions, and batch processing.
#'
#' Identical origin-destination pairs within \code{data} are deduplicated
#' before querying the API; results are propagated back to all matching rows.
#' Destinations are batched up to 25 per API call (grouped by unique origin)
#' to minimise quota usage.
#'
#' @param data A data frame containing origin and destination coordinates.
#' @param origin_lat Column name for origin latitude (default: "origin_lat").
#' @param origin_lon Column name for origin longitude (default: "origin_lon").
#' @param dest_lat Column name for destination latitude (default: "dest_lat").
#' @param dest_lon Column name for destination longitude (default: "dest_lon").
#' @param api_key Google Maps API key. If NULL, reads \code{GOOGLE_MAPS_API_KEY}
#'   from the environment.
#' @param delay_seconds Delay in seconds between API calls to stay within
#'   per-second rate limits (default: 0.1).
#' @param mode Travel mode: "driving", "walking", "bicycling", or "transit"
#'   (default: "driving").
#' @param departure_time Departure time for the trip. One of:
#'   \itemize{
#'     \item NULL (default): no specific time, returns typical free-flow duration.
#'     \item "now": current time with live traffic (returns \code{duration_in_traffic}).
#'     \item POSIXct / POSIXt object: specific future time.
#'     \item Character string "YYYY-MM-DD HH:MM:SS".
#'   }
#' @param traffic_model Traffic model when \code{departure_time} is set:
#'   "best_guess", "pessimistic", or "optimistic" (default: "best_guess").
#'
#' @return The original \code{data} frame with three appended columns:
#'   \itemize{
#'     \item \code{driving_time_min}: Travel time in minutes (numeric).
#'       When \code{departure_time} is set, this reflects traffic conditions
#'       (\code{duration_in_traffic}); otherwise it is the typical duration.
#'     \item \code{distance_km}: Distance in kilometres (numeric).
#'     \item \code{api_status}: API element status string. "OK" indicates
#'       success; other values ("NOT_FOUND", "ZERO_RESULTS", "Error: …")
#'       indicate failure for that pair.
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data <- data.frame(
#'   origin_lat = c(40.7128, 34.0522),
#'   origin_lon = c(-74.0060, -118.2437),
#'   dest_lat   = c(42.3601, 37.7749),
#'   dest_lon   = c(-71.0589, -122.4194)
#' )
#'
#' # Basic usage (reads GOOGLE_MAPS_API_KEY env var)
#' results <- calculate_driving_time(data)
#'
#' # With live traffic
#' results <- calculate_driving_time(data, departure_time = "now")
#'
#' # Specific future departure
#' results <- calculate_driving_time(data, departure_time = "2024-03-15 08:00:00")
#'
#' # Custom column names
#' results <- calculate_driving_time(data,
#'                                   origin_lat = "lat_HS",
#'                                   origin_lon = "lon_HS",
#'                                   dest_lat   = "lat_coll",
#'                                   dest_lon   = "lon_coll")
#' }
calculate_driving_time <- function(data,
                                   origin_lat    = "origin_lat",
                                   origin_lon    = "origin_lon",
                                   dest_lat      = "dest_lat",
                                   dest_lon      = "dest_lon",
                                   api_key       = NULL,
                                   delay_seconds = 0.1,
                                   mode          = "driving",
                                   departure_time = NULL,
                                   traffic_model  = "best_guess") {

  # ── Dependency check ────────────────────────────────────────────────────────
  if (!requireNamespace("googleway", quietly = TRUE)) {
    stop("Package 'googleway' is required. Install with: install.packages('googleway')")
  }

  # ── API key ─────────────────────────────────────────────────────────────────
  if (is.null(api_key)) {
    api_key <- Sys.getenv("GOOGLE_MAPS_API_KEY")
    if (api_key == "") {
      stop("API key not found. Set it with set_api_key() or provide via the api_key argument.")
    }
  }

  # ── Column presence ─────────────────────────────────────────────────────────
  required_cols <- c(origin_lat, origin_lon, dest_lat, dest_lon)
  missing_cols  <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop("Missing columns in data: ", paste(missing_cols, collapse = ", "))
  }

  # ── Mode ────────────────────────────────────────────────────────────────────
  valid_modes <- c("driving", "walking", "bicycling", "transit")
  if (!mode %in% valid_modes) {
    stop("Invalid mode. Choose from: ", paste(valid_modes, collapse = ", "))
  }

  # ── Departure time ──────────────────────────────────────────────────────────
  departure_timestamp <- NULL
  if (!is.null(departure_time)) {
    if (!mode %in% c("driving", "transit")) {
      warning("departure_time is only supported for 'driving' and 'transit' modes. Ignoring.")
      departure_time <- NULL
    } else {
      departure_timestamp <- process_departure_time(departure_time)
    }
  }

  # ── Traffic model ───────────────────────────────────────────────────────────
  valid_traffic_models <- c("best_guess", "pessimistic", "optimistic")
  if (!traffic_model %in% valid_traffic_models) {
    stop("Invalid traffic_model. Choose from: ", paste(valid_traffic_models, collapse = ", "))
  }

  # ── Coordinate validation ───────────────────────────────────────────────────
  validate_coordinates(data, origin_lat, origin_lon, dest_lat, dest_lon)

  # ── Progress header ─────────────────────────────────────────────────────────
  if (!is.null(departure_time)) {
    cat("Calculating driving times for", nrow(data), "routes with departure time settings...\n")
    if (is.character(departure_time) && tolower(departure_time) == "now") {
      cat("Using current traffic conditions\n")
    } else {
      cat("Departure time:",
          format(as.POSIXct(departure_timestamp, origin = "1970-01-01"), "%Y-%m-%d %H:%M:%S"), "\n")
    }
    cat("Traffic model:", traffic_model, "\n\n")
  } else {
    cat("Calculating driving times for", nrow(data), "routes...\n")
  }

  # ── Initialise result columns ───────────────────────────────────────────────
  data$driving_time_min <- NA_real_
  data$distance_km      <- NA_real_
  data$api_status       <- NA_character_

  # ── Deduplication ───────────────────────────────────────────────────────────
  # Build a key for each row; process only unique pairs; propagate back after.
  key_cols <- c(origin_lat, origin_lon, dest_lat, dest_lon)
  pair_key <- do.call(paste, c(data[key_cols], sep = "\x00"))
  unique_idx <- which(!duplicated(pair_key))
  n_unique   <- length(unique_idx)
  n_dupes    <- nrow(data) - n_unique

  if (n_dupes > 0) {
    cat("Deduplication: ", n_unique, " unique pairs from ", nrow(data),
        " rows (", n_dupes, " duplicate(s) will reuse cached results)\n\n", sep = "")
  }

  # ── Group unique pairs by origin for batched calls ──────────────────────────
  BATCH_SIZE <- 25L
  orig_keys  <- paste(data[[origin_lat]][unique_idx],
                      data[[origin_lon]][unique_idx], sep = "\x00")
  groups     <- split(unique_idx, orig_keys)

  cat("Batching: ", n_unique, " unique pairs across ",
      length(groups), " origin(s), up to ", BATCH_SIZE,
      " destinations per API call\n\n", sep = "")

  n_processed <- 0L
  fatal_hit   <- FALSE

  for (orig_key in names(groups)) {
    if (fatal_hit) break

    row_idxs <- groups[[orig_key]]
    origin   <- paste(data[[origin_lat]][row_idxs[1]],
                      data[[origin_lon]][row_idxs[1]], sep = ",")

    # Split this origin's destinations into chunks of BATCH_SIZE
    chunks <- split(row_idxs,
                    ceiling(seq_along(row_idxs) / BATCH_SIZE))

    for (chunk_idxs in chunks) {
      if (fatal_hit) break

      dests <- paste(data[[dest_lat]][chunk_idxs],
                     data[[dest_lon]][chunk_idxs], sep = ",")

      batch <- get_batch_routes(
        origin         = origin,
        destinations   = dests,
        api_key        = api_key,
        mode           = mode,
        departure_time = departure_timestamp,
        traffic_model  = traffic_model
      )

      data$driving_time_min[chunk_idxs] <- batch$duration_minutes
      data$distance_km[chunk_idxs]      <- batch$distance_km
      data$api_status[chunk_idxs]       <- batch$status

      # ── Fatal status detection ─────────────────────────────────────────────
      fatal_match <- batch$status[!is.na(batch$status)] %in% FATAL_API_STATUSES
      if (any(fatal_match)) {
        fatal_status <- batch$status[batch$status %in% FATAL_API_STATUSES][1]
        warning("Fatal API error '", fatal_status,
                "' received — stopping early. ",
                "Check your API key and quota before retrying.")
        fatal_hit <- TRUE
        break
      }

      n_processed <- n_processed + length(chunk_idxs)
      if (n_processed %% 100 == 0 || n_processed == n_unique) {
        cat("Processed", n_processed, "of", n_unique, "unique pairs\n")
      }

      if (length(chunk_idxs) == BATCH_SIZE || orig_key != tail(names(groups), 1)) {
        Sys.sleep(delay_seconds)
      }
    }
  }

  # ── Propagate results to duplicate rows ─────────────────────────────────────
  if (n_dupes > 0) {
    # For every row, find the index of its canonical (first-seen) counterpart
    source_idx <- unique_idx[match(pair_key, pair_key[unique_idx])]
    data$driving_time_min <- data$driving_time_min[source_idx]
    data$distance_km      <- data$distance_km[source_idx]
    data$api_status       <- data$api_status[source_idx]
  }

  # ── Summary ─────────────────────────────────────────────────────────────────
  n_ok   <- sum(data$api_status == "OK",  na.rm = TRUE)
  n_fail <- sum(data$api_status != "OK",  na.rm = TRUE)
  cat("\nComplete! ", nrow(data), " routes total (", n_unique,
      " API calls made).\n", sep = "")
  cat("Successful:", n_ok, " | Failed:", n_fail, "\n")

  return(data)
}
