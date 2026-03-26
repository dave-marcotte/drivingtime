# Fatal API-level statuses that mean all future calls will also fail
FATAL_API_STATUSES <- c("REQUEST_DENIED", "OVER_DAILY_LIMIT")

#' Validate coordinate columns before hitting the API
#' @keywords internal
validate_coordinates <- function(data, origin_lat, origin_lon, dest_lat, dest_lon) {
  errors <- character(0)

  for (col in c(origin_lat, origin_lon, dest_lat, dest_lon)) {
    n_na <- sum(is.na(data[[col]]))
    if (n_na > 0) {
      errors <- c(errors, sprintf("%d NA value(s) in column '%s'", n_na, col))
    }
  }

  for (col in c(origin_lat, dest_lat)) {
    vals  <- data[[col]]
    n_bad <- sum(!is.na(vals) & (vals < -90 | vals > 90))
    if (n_bad > 0) {
      errors <- c(errors,
        sprintf("%d value(s) in '%s' outside valid latitude range [-90, 90]", n_bad, col))
    }
  }

  for (col in c(origin_lon, dest_lon)) {
    vals  <- data[[col]]
    n_bad <- sum(!is.na(vals) & (vals < -180 | vals > 180))
    if (n_bad > 0) {
      errors <- c(errors,
        sprintf("%d value(s) in '%s' outside valid longitude range [-180, 180]", n_bad, col))
    }
  }

  if (length(errors) > 0) {
    stop("Invalid coordinate data:\n  ", paste(errors, collapse = "\n  "))
  }

  invisible(NULL)
}

#' Call the Distance Matrix API for one origin and up to 25 destinations
#'
#' Returns a list with duration_minutes, distance_km, and status vectors of
#' length equal to length(destinations). Retries on transient rate-limit
#' errors with exponential backoff. Scrubs the API key from any error message
#' before storing it.
#'
#' @keywords internal
get_batch_routes <- function(origin, destinations, api_key, mode,
                             departure_time, traffic_model,
                             max_retries = 3L) {
  n          <- length(destinations)
  last_error <- NULL

  for (attempt in seq_len(max_retries)) {
    api_params <- list(
      origins      = origin,
      destinations = destinations,
      key          = api_key,
      mode         = mode
    )
    if (!is.null(departure_time)) {
      api_params$departure_time <- departure_time
      api_params$traffic_model  <- traffic_model
    }

    raw <- tryCatch(
      do.call(googleway::google_distance, api_params),
      error = function(e) e
    )

    # ── Network / package error ───────────────────────────────────────────────
    if (inherits(raw, "error")) {
      last_error <- raw
      msg <- gsub(api_key, "[REDACTED]", conditionMessage(raw), fixed = TRUE)
      is_rate_limit <- grepl("429|OVER_QUERY_LIMIT|rate.limit", msg, ignore.case = TRUE)
      if (attempt < max_retries && is_rate_limit) {
        wait_sec <- 2^attempt
        message("Rate limit hit; retrying in ", wait_sec,
                "s (attempt ", attempt, "/", max_retries, ")...")
        Sys.sleep(wait_sec)
        next
      }
      break
    }

    # ── Parse elements: 1 origin → N destination results ─────────────────────
    elements    <- raw$rows$elements[[1]]
    use_traffic <- !is.null(departure_time)

    duration_minutes <- rep(NA_real_,      n)
    distance_km      <- rep(NA_real_,      n)
    status           <- rep(NA_character_, n)

    # jsonlite returns a data.frame when all elements share the same structure
    # (the common case); it falls back to a list when statuses are mixed.
    if (is.data.frame(elements)) {
      status <- elements$status
      ok     <- status == "OK"
      if (any(ok)) {
        has_traffic <- use_traffic && "duration_in_traffic" %in% names(elements)
        if (has_traffic) {
          duration_minutes[ok] <- elements$duration_in_traffic$value[ok] / 60
        } else {
          duration_minutes[ok] <- elements$duration$value[ok] / 60
        }
        distance_km[ok] <- elements$distance$value[ok] / 1000
      }
    } else {
      # list fallback (mixed statuses)
      for (j in seq_len(n)) {
        el        <- elements[[j]]
        status[j] <- el$status
        if (identical(el$status, "OK")) {
          has_traffic <- use_traffic && !is.null(el$duration_in_traffic)
          dur <- if (has_traffic) el$duration_in_traffic$value else el$duration$value
          duration_minutes[j] <- dur / 60
          distance_km[j]      <- el$distance$value / 1000
        }
      }
    }

    return(list(duration_minutes = duration_minutes,
                distance_km      = distance_km,
                status           = status))
  }

  # ── All retries exhausted ─────────────────────────────────────────────────
  msg <- if (!is.null(last_error)) {
    gsub(api_key, "[REDACTED]", conditionMessage(last_error), fixed = TRUE)
  } else {
    "Unknown error"
  }
  list(duration_minutes = rep(NA_real_,                n),
       distance_km      = rep(NA_real_,                n),
       status           = rep(paste("Error:", msg),    n))
}

#' Process departure time into Unix timestamp
#' @keywords internal
process_departure_time <- function(departure_time) {
  if (is.null(departure_time)) return(NULL)

  if (is.character(departure_time) && tolower(departure_time) == "now") {
    return(as.integer(Sys.time()))
  }

  if (inherits(departure_time, "POSIXct") || inherits(departure_time, "POSIXt")) {
    return(as.integer(departure_time))
  }

  if (is.character(departure_time)) {
    tryCatch({
      dt <- as.POSIXct(departure_time, tz = "UTC")
      if (is.na(dt)) {
        stop("Could not parse departure_time. Use format: 'YYYY-MM-DD HH:MM:SS'")
      }
      if (dt < Sys.time()) {
        warning("Departure time is in the past. Using current time instead.")
        return(as.integer(Sys.time()))
      }
      return(as.integer(dt))
    }, error = function(e) {
      stop("Could not parse departure_time. Use format: 'YYYY-MM-DD HH:MM:SS' or 'now'")
    })
  }

  if (is.numeric(departure_time)) return(as.integer(departure_time))

  stop("Invalid departure_time format. Use 'now', POSIXct object, or 'YYYY-MM-DD HH:MM:SS' string")
}
