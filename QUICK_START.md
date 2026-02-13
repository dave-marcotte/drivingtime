# QUICK START GUIDE - drivingtime Package

## For You (Package Author)

### What You Have
- ✅ A complete R package called `drivingtime`
- ✅ All necessary files in the `/drivingtime` folder
- ✅ A ZIP file (`drivingtime.zip`) ready to share

### How to Install on Your Computer

```r
# In R or RStudio:
install.packages("devtools")
devtools::install("/path/to/drivingtime")  # Use actual path to folder

# Or from the ZIP file:
devtools::install_local("/path/to/drivingtime.zip")
```

### How to Use After Installing

```r
library(drivingtime)

# Set API key
set_api_key("YOUR_GOOGLE_MAPS_API_KEY")

# Load data (IMPORTANT: Don't open in Excel first!)
data <- read_coordinates("/yourdata.csv")

# Calculate driving times
results <- calculate_driving_time(
  data,
  origin_lat = "lat_HS",
  origin_lon = "lon_HS",
  dest_lat = "lat_coll",
  dest_lon = "lon_coll",
  api_key <- Sys.getenv("GOOGLE_MAPS_API_KEY")
)

# Save results
save_results(results, "/results.csv")
```

---

## For Others (People You Share With)

### Step 1: Get the Package
You'll receive a file called `drivingtime.zip`

### Step 2: Install It
```r
# Install devtools (first time only)
install.packages("devtools")

# Install drivingtime package from ZIP
devtools::install_local("~/Downloads/drivingtime.zip")
```

### Step 3: Get a Google Maps API Key
1. Go to https://console.cloud.google.com
2. Create/select a project
3. Enable "Distance Matrix API"
4. Create API credentials
5. Copy your API key

### Step 4: Use It
```r
library(drivingtime)

# Set your API key
set_api_key("YOUR_API_KEY_HERE")

# Load your data
data <- read_coordinates("your_data.csv")

# Calculate driving times (basic)
results <- calculate_driving_time(data)

# Or with custom column names
results <- calculate_driving_time(
  data,
  origin_lat = "your_origin_lat_column",
  origin_lon = "your_origin_lon_column",
  dest_lat = "your_dest_lat_column",
  dest_lon = "your_dest_lon_column",
  api_key <- Sys.getenv("GOOGLE_MAPS_API_KEY")
)

# Save results
save_results(results, "output.csv")
```

---

## Important Notes

### Data Format
Your CSV must have latitude and longitude columns with **precise decimal coordinates**:
- ✅ Good: `40.7127837`, `-74.0059413`
- ❌ Bad: `41`, `-74` (too imprecise)

### Excel Warning
**NEVER open your CSV in Excel before loading into R!**
Excel will round your coordinates and destroy the precision.

### API Costs
Google Maps Distance Matrix API charges per request:
- Check current pricing: https://developers.google.com/maps/billing-and-pricing
- Set billing limits in Google Cloud Console to avoid surprises

---

## Files Included

- `DESCRIPTION` - Package metadata
- `NAMESPACE` - Function exports
- `LICENSE` - MIT License
- `README.md` - Full documentation
- `INSTALLATION_GUIDE.md` - Detailed installation instructions
- `example_usage.R` - Example scripts
- `R/` folder - Package code
  - `calculate_driving_time.R` - Main function
  - `helpers.R` - Internal helpers
  - `utils.R` - Utility functions

---

## Need Help?

See the full documentation in `README.md` or `INSTALLATION_GUIDE.md`
