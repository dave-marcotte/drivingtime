# ============================================================================
# EXAMPLE: How to use the drivingtime package
# ============================================================================
# This script shows how to use the drivingtime package after installation

# ----------------------------------------------------------------------------
# 1. INSTALL THE PACKAGE (do this once)
# ----------------------------------------------------------------------------

# Option A: Install from local folder
# devtools::install("path/to/drivingtime")

# Option B: Install from ZIP file
# devtools::install_local("drivingtime.zip")

# ----------------------------------------------------------------------------
# 2. LOAD THE PACKAGE
# ----------------------------------------------------------------------------

library(drivingtime)

# ----------------------------------------------------------------------------
# 3. SET YOUR API KEY
# ----------------------------------------------------------------------------

# Set your Google Maps API key (replace with your actual key)
set_api_key("YOUR_GOOGLE_MAPS_API_KEY")

# To make it permanent, add this line to your .Renviron file:
# GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY

# ----------------------------------------------------------------------------
# 4. LOAD YOUR DATA
# ----------------------------------------------------------------------------

# Option A: Read from CSV file
data <- read_coordinates("your_data.csv")

# Option B: Create data frame manually
data <- data.frame(
  origin_lat = c(40.7128, 34.0522),
  origin_lon = c(-74.0060, -118.2437),
  dest_lat = c(42.3601, 37.7749),
  dest_lon = c(-71.0589, -122.4194)
)

# ----------------------------------------------------------------------------
# 5. CALCULATE DRIVING TIMES
# ----------------------------------------------------------------------------

# Basic usage (with default column names)
results <- calculate_driving_time(data)

# With custom column names (e.g., for high schools to colleges)
results <- calculate_driving_time(
  data,
  origin_lat = "lat_HS",      # Your column name for origin latitude
  origin_lon = "lon_HS",      # Your column name for origin longitude
  dest_lat = "lat_coll",      # Your column name for destination latitude
  dest_lon = "lon_coll"       # Your column name for destination longitude
)

# ----------------------------------------------------------------------------
# 6. VIEW RESULTS
# ----------------------------------------------------------------------------

# View in RStudio
View(results)

# See first few rows
head(results)

# Summary statistics
summary(results[, c("driving_time_min", "distance_km")])

# ----------------------------------------------------------------------------
# 7. SAVE RESULTS
# ----------------------------------------------------------------------------

save_results(results, "output_with_driving_times.csv")

# ============================================================================
# ADVANCED EXAMPLES
# ============================================================================

# Example 1: With current traffic conditions
# ----------------------------------------------------------------------------
results_traffic <- calculate_driving_time(
  data,
  departure_time = "now"
)

# Example 2: For a specific future time (e.g., Monday morning at 8 AM)
# ----------------------------------------------------------------------------
results_future <- calculate_driving_time(
  data,
  departure_time = "2024-03-18 08:00:00"
)

# Example 3: With pessimistic traffic estimates
# ----------------------------------------------------------------------------
results_pessimistic <- calculate_driving_time(
  data,
  departure_time = "now",
  traffic_model = "pessimistic"
)

# Example 4: Different travel modes
# ----------------------------------------------------------------------------

# Walking
results_walk <- calculate_driving_time(data, mode = "walking")

# Bicycling
results_bike <- calculate_driving_time(data, mode = "bicycling")

# Public transit
results_transit <- calculate_driving_time(data, mode = "transit")

# Example 5: Adjust delay for large datasets
# ----------------------------------------------------------------------------
# If you have many routes, you might want to increase the delay
# to avoid hitting API rate limits
results <- calculate_driving_time(
  data,
  delay_seconds = 0.2  # Slower, but safer for large datasets
)

# ============================================================================
# TROUBLESHOOTING
# ============================================================================

# Check if coordinates are properly formatted
# Coordinates should have many decimal places (e.g., 40.7128, not 41)
head(data[, c("origin_lat", "origin_lon", "dest_lat", "dest_lon")])

# Check for missing coordinates
sum(is.na(data$origin_lat))
sum(is.na(data$origin_lon))
sum(is.na(data$dest_lat))
sum(is.na(data$dest_lon))

# Check which routes failed
failed_routes <- results[results$api_status != "OK", ]
if (nrow(failed_routes) > 0) {
  print("Failed routes:")
  print(failed_routes)
}
