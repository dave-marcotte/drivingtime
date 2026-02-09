# drivingtime

Calculate driving times and distances between coordinates using the Google Maps Distance Matrix API.

## Installation

You can install this package directly from the source folder:

```r
# Install devtools if you don't have it
install.packages("devtools")

# Install drivingtime from local folder
devtools::install("path/to/drivingtime")

# Or install from a ZIP file
devtools::install_local("drivingtime.zip")
```

## Prerequisites

1. **Google Maps API Key**: You need a Google Maps API key with the Distance Matrix API enabled.
   - Get one at: https://console.cloud.google.com/google/maps-apis
   - Enable the "Distance Matrix API" for your project

2. **Required R packages**: The package will automatically install:
   - `googleway`
   - `dplyr`

## Quick Start

```r
library(drivingtime)

# 1. Set your API key
set_api_key("YOUR_GOOGLE_MAPS_API_KEY")

# 2. Prepare your data
data <- data.frame(
  origin_lat = c(40.7128, 34.0522),
  origin_lon = c(-74.0060, -118.2437),
  dest_lat = c(42.3601, 37.7749),
  dest_lon = c(-71.0589, -122.4194)
)

# 3. Calculate driving times
results <- calculate_driving_time(data)

# 4. View results
head(results)
```

## Usage Examples

### Basic Usage

```r
library(drivingtime)

# Set API key
set_api_key("YOUR_API_KEY")

# Load data from CSV
data <- read_coordinates("my_locations.csv")

# Calculate driving times
results <- calculate_driving_time(data)

# Save results
save_results(results, "output_with_times.csv")
```

### Custom Column Names

If your data has different column names:

```r
results <- calculate_driving_time(
  data,
  origin_lat = "lat_HS",      # Your origin latitude column
  origin_lon = "lon_HS",      # Your origin longitude column
  dest_lat = "lat_coll",      # Your destination latitude column
  dest_lon = "lon_coll"       # Your destination longitude column
)
```

### With Traffic Conditions

```r
# Using current traffic
results <- calculate_driving_time(data, departure_time = "now")

# For a specific future time (e.g., Monday morning commute)
results <- calculate_driving_time(
  data, 
  departure_time = "2024-03-18 08:00:00"
)

# With pessimistic traffic estimates
results <- calculate_driving_time(
  data,
  departure_time = "now",
  traffic_model = "pessimistic"
)
```

### Different Travel Modes

```r
# Walking
results <- calculate_driving_time(data, mode = "walking")

# Bicycling
results <- calculate_driving_time(data, mode = "bicycling")

# Public transit
results <- calculate_driving_time(data, mode = "transit")
```

## Data Format

Your input data should be a data frame with latitude and longitude columns:

```r
# Default column names
data <- data.frame(
  origin_lat = c(40.7128, 34.0522),
  origin_lon = c(-74.0060, -118.2437),
  dest_lat = c(42.3601, 37.7749),
  dest_lon = c(-71.0589, -122.4194)
)

# Or use custom column names and specify them in the function
```

**Important**: Coordinates must be in decimal format with high precision. 
**Do NOT open CSV files in Excel before loading into R** - Excel will round 
coordinates and ruin your data!

## Output

The function returns your original data frame with three additional columns:

- `driving_time_min`: Travel time in minutes
- `distance_km`: Distance in kilometers  
- `api_status`: API response status ("OK" for successful requests)

## Function Reference

### `calculate_driving_time()`
Main function to calculate driving times between coordinates.

**Parameters:**
- `data`: Data frame with coordinates
- `origin_lat`: Column name for origin latitude (default: "origin_lat")
- `origin_lon`: Column name for origin longitude (default: "origin_lon")
- `dest_lat`: Column name for destination latitude (default: "dest_lat")
- `dest_lon`: Column name for destination longitude (default: "dest_lon")
- `api_key`: Google Maps API key (optional if set via `set_api_key()`)
- `delay_seconds`: Delay between API calls (default: 0.1)
- `mode`: Travel mode - "driving", "walking", "bicycling", "transit" (default: "driving")
- `departure_time`: Departure time - NULL, "now", or "YYYY-MM-DD HH:MM:SS" (default: NULL)
- `traffic_model`: Traffic model - "best_guess", "pessimistic", "optimistic" (default: "best_guess")

### `set_api_key(api_key)`
Set your Google Maps API key for the session.

### `read_coordinates(file, ...)`
Read coordinates from a CSV file.

### `save_results(data, file, ...)`
Save results to a CSV file.

## Tips

1. **API Rate Limits**: The function includes a small delay between requests (default 0.1 seconds) to avoid hitting rate limits.

2. **Cost**: Google Maps API charges for Distance Matrix requests. Monitor your usage in the Google Cloud Console.

3. **Coordinate Precision**: Make sure your coordinates have sufficient decimal places (e.g., 40.7128, not 41).

4. **Excel Warning**: Never open your CSV file in Excel before loading it in R - Excel will round your coordinates!

5. **Traffic Data**: Traffic predictions work best for times within the next week.

## License

MIT License

## Support

For issues or questions, please open an issue on the package repository.
