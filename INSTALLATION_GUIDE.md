# How to Install and Share the drivingtime Package

## For Package Authors (You)

### Step 1: Zip the package folder
1. Locate the `drivingtime` folder on your computer
2. Right-click and select "Compress" (Mac) or "Send to > Compressed folder" (Windows)
3. This creates `drivingtime.zip`

### Step 2: Share the package
You can share the package with others by:
- **Email**: Send them the `drivingtime.zip` file
- **Dropbox/Google Drive**: Upload and share the link
- **GitHub**: Upload to a GitHub repository (see GitHub section below)

---

## For Package Users (People you share with)

### Prerequisites
1. R installed (version 3.5 or higher)
2. RStudio (recommended)
3. Google Maps API key with Distance Matrix API enabled

### Installation Steps

#### Step 1: Install devtools
Open R or RStudio and run:
```r
install.packages("devtools")
```

#### Step 2: Install the package

**Option A: From ZIP file**
```r
# Download the drivingtime.zip file
# Then install it:
devtools::install_local("~/Downloads/drivingtime.zip")
```

**Option B: From extracted folder**
```r
# If you extracted the ZIP file:
devtools::install("~/Downloads/drivingtime")
```

**Option C: From GitHub (if you upload it there)**
```r
devtools::install_github("yourusername/drivingtime")
```

#### Step 3: Load and use
```r
library(drivingtime)

# Set your API key
set_api_key("YOUR_GOOGLE_MAPS_API_KEY")

# Load your data
data <- read_coordinates("your_file.csv")

# Calculate driving times
results <- calculate_driving_time(data)

# Save results
save_results(results, "output.csv")
```

---

## Uploading to GitHub (Optional but Recommended)

### Why GitHub?
- Easy sharing with a simple link
- Version control
- Users can install with one command
- Free hosting

### How to upload to GitHub:

1. **Create a GitHub account** (if you don't have one)
   - Go to https://github.com
   - Sign up for free

2. **Create a new repository**
   - Click "New repository"
   - Name it "drivingtime"
   - Make it Public
   - Don't initialize with README (we already have one)

3. **Upload your files**
   - Click "uploading an existing file"
   - Drag and drop all files from the `drivingtime` folder
   - Click "Commit changes"

4. **Share with others**
   - Your package URL will be: `https://github.com/yourusername/drivingtime`
   - Others can install with:
   ```r
   devtools::install_github("yourusername/drivingtime")
   ```

---

## Getting a Google Maps API Key

Users will need their own API key:

1. Go to https://console.cloud.google.com
2. Create a new project (or select existing)
3. Enable "Distance Matrix API"
4. Go to Credentials > Create Credentials > API Key
5. Copy the API key

**Important**: Set up billing limits to avoid unexpected charges!

---

## Package Structure

The package contains:
```
drivingtime/
├── DESCRIPTION          # Package metadata
├── NAMESPACE           # Exported functions
├── LICENSE             # MIT License
├── README.md           # Documentation
├── example_usage.R     # Example script
└── R/                  # R code
    ├── calculate_driving_time.R
    ├── helpers.R
    └── utils.R
```

---

## Support

If users have questions, direct them to:
1. The README.md file
2. The example_usage.R script
3. Your email/GitHub issues page

---

## Version Updates

To update the package:
1. Make changes to the R files
2. Update version number in DESCRIPTION file
3. Re-zip and share (or push to GitHub)
4. Users re-install with the same command
