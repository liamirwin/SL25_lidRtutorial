# Read/Plot/Query/Validate
# https://liamirwin.github.io/SL25_lidRtutorial/01_read.html
# =========================
# R Packages
# ------------
# Ensure required packages are installed and loaded
pkgs <- c("lidR", "terra", "viridis", "future", "sf", "mapview")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p)
  }
}
# Install and load lidRmetrics from GitHub if not already
if (!requireNamespace("lidRmetrics", quietly = TRUE)) {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools")
  }
  devtools::install_github("ptompalski/lidRmetrics")
}
# Environment setup
# -----------------
# Clear current workspace and load required packages
rm(list = ls(globalenv()))
library(lidR)

# -------------------------------------------------------------------
# Basic Usage
# -------------------------------------------------------------------

# Load and inspect lidar data
# ----------------------------
# Load the sample point cloud
las <- readLAS(files = "data/fm_norm.laz")

# Inspect header and attribute information
las

# Check the memory size of the loaded lidar object
format(object.size(las), "Mb")

# Visualize the lidar data
# ----------------------
# Default 3D plot
plot(las)

# Colour by classification
plot(las, color = "Classification")

# Colour by intensity
plot(las, color = "Intensity")

# Colour by scan angle rank
plot(las, color = "ScanAngleRank")

# -------------------------------------------------------------------
# Point Classification and Filtering
# -------------------------------------------------------------------

# Load a version with only ground points (classification == 2)
las <- readLAS(files = "data/fm_class.laz", filter = "-keep_class 2")
plot(las)

# Keep only first-return points
las <- readLAS(files = "data/fm_norm.laz", filter = "-keep_first")
las
plot(las)

#    Select only XYZ coordinates to reduce memory usage
las <- readLAS(files = "data/fm_norm.laz", select = "xyz")
las@data
format(object.size(las), "Mb")

# Filter an in-memory LAS object by attribute
# Load the lidar file with all the all attributes 
las <- readLAS(files = "data/fm_class.laz")
# Filter points with Classification == 2
class_2 <- filter_poi(las = las, Classification == 2L)

# Combine queries to filter points with Classification 2 and ReturnNumber == 1
first_returns <- filter_poi(las = las, Classification == 2L & ReturnNumber == 1L)
plot(class_2)
plot(first_returns)

# -------------------------------------------------------------------
# Exercises
# -------------------------------------------------------------------

# E1. Using the plot() function, plot the point cloud with a different attribute
#     that has not been done yet. Try adding axis = TRUE, legend = TRUE.

# E2. Create a filtered las object of returns that have an Intensity greater than 50,
#     and plot it.

# E3. Read in the LAS file with only xyz and intensity attributes.
