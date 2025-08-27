# Read/Plot/Query/Validate
# https://liamirwin.github.io/LPS_lidRtutorial/01_read.html
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
las <- readLAS(files = "data/zrh_norm.laz")

# Inspect header and attribute information
las

# Check the memory size of the loaded lidar object
format(object.size(las), "Mb")

# Visualize the lidar data
# ----------------------
# Default 3D plot
plot(las)

# Colour by elevation (Z)
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
las_ground <- readLAS(files = "data/zrh_class.laz", filter = "-keep_class 2")
plot(las_ground)

# Keep only first-return points
las_first <- readLAS(files = "data/zrh_norm.laz", filter = "-keep_first")
las_first
plot(las_first)

#    Select only XYZ coordinates to reduce memory usage
las_xyz <- readLAS(files = "data/zrh_norm.laz", select = "xyz")
las_xyz@data
format(object.size(las_xyz), "Mb")

# Filter an in-memory LAS object by attribute
# Flter points with Classification == 2 (ground)
las <- readLAS('data/zrh_class.laz')
class_2 <- filter_poi(las = las, Classification == 2L)
plot(class_2)

# Combine filters: ground AND first returns
first_ground <- filter_poi(las = las, Classification == 2L & ReturnNumber == 1L)
plot(first_ground)

# -------------------------------------------------------------------
# Exercises
# -------------------------------------------------------------------

# E1. Using the plot() function, plot the point cloud with a different attribute
#     that has not been done yet. Try adding axis = TRUE, legend = TRUE.

# E2. Create a filtered las object of returns that have an Intensity greater than 50,
#     and plot it.

# E3. Read in the LAS file with only xyz and intensity attributes.
