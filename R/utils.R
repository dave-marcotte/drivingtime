#' Set Google Maps API Key
#'
#' Set your Google Maps API key for the current R session. The key will be
#' stored in the GOOGLE_MAPS_API_KEY environment variable.
#'
#' @param api_key Your Google Maps API key (character string)
#'
#' @details
#' To make the API key permanent across sessions, add it to your .Renviron file:
#' \code{GOOGLE_MAPS_API_KEY=YOUR_API_KEY}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' set_api_key("YOUR_API_KEY_HERE")
#' }
set_api_key <- function(api_key) {
  Sys.setenv(GOOGLE_MAPS_API_KEY = api_key)
  cat("API key set successfully for this session.\n")
  cat("To make it permanent, add this to your .Renviron file:\n")
  cat("GOOGLE_MAPS_API_KEY=", api_key, "\n", sep = "")
}

#' Read coordinates from CSV file
#'
#' Read a CSV file containing coordinate data. This is a wrapper around
#' read.csv that provides helpful feedback about the loaded data.
#'
#' @param file Path to CSV file
#' @param ... Additional arguments passed to read.csv
#'
#' @return Data frame with the loaded data
#' @export
#'
#' @examples
#' \dontrun{
#' data <- read_coordinates("my_addresses.csv")
#' }
read_coordinates <- function(file, ...) {
  data <- read.csv(file, ...)
  cat("Loaded", nrow(data), "rows from", file, "\n")
  cat("Columns:", paste(names(data), collapse = ", "), "\n")
  return(data)
}

#' Save results to CSV file
#'
#' Save the results data frame to a CSV file.
#'
#' @param data Data frame with results to save
#' @param file Output file path
#' @param ... Additional arguments passed to write.csv
#'
#' @export
#'
#' @examples
#' \dontrun{
#' save_results(results, "driving_times_output.csv")
#' }
save_results <- function(data, file, ...) {
  write.csv(data, file, row.names = FALSE, ...)
  cat("Results saved to", file, "\n")
  cat("Saved", nrow(data), "rows with", ncol(data), "columns\n")
}
