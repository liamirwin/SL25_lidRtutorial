# Canopy Height Models
# https://liamirwin.github.io/LPS_lidRtutorial/03_chm.html

# Environment setup
# -----------------
# Clear workspace and load required packages
rm(list = ls(globalenv()))
library(lidR)
library(terra)

# -------------------------------------------------------------------
# Data Preprocessing
# -------------------------------------------------------------------

# Load lidar data and decimate to simulate lower density (20 -> 10 pts/m²)
las <- readLAS(files = "data/zrh_norm.laz")
las <- decimate_points(las, random(density = 10))

# Visualize the point cloud
plot(las)

# -------------------------------------------------------------------
# Point-to-Raster CHM (p2r)
# -------------------------------------------------------------------

# Generate CHM at 2m resolution
chm <- rasterize_canopy(las = las, res = 2, algorithm = p2r())
plot(chm)

# Generate CHM at 1m resolution
chm <- rasterize_canopy(las = las, res = 1, algorithm = p2r())
plot(chm)

# Generate CHM at 0.5m with subcircle to fill gaps
chm <- rasterize_canopy(las = las, res = 0.5, algorithm = p2r(subcircle = 0.15))
plot(chm)

# Generate CHM at 0.5m with larger subcircle
chm <- rasterize_canopy(las = las, res = 0.5, algorithm = p2r(subcircle = 0.8))
plot(chm)

# Fill empty pixels using TIN interpolation
chm <- rasterize_canopy(las = las, res = 0.5, algorithm = p2r(subcircle = 0.0,
                                                              na.fill = tin()))
plot(chm)

# -------------------------------------------------------------------
# Triangulation-Based CHM (pitfree)
# -------------------------------------------------------------------

# Define thresholds and edge length
thresholds <- c(0, 5, 10, 20, 25, 30)
max_edge <- c(0, 1.35)

# Generate pitfree CHM at 0.5m resolution
chm <- rasterize_canopy(las = las, res = 0.5, algorithm = pitfree(thresholds,
                                                                  max_edge))
plot(chm)

# Generate pitfree CHM with subcircle for finer detail
chm <- rasterize_canopy(las = las, res = 0.25, algorithm = pitfree(thresholds,
                                                                   max_edge, 0.1))
plot(chm)

# -------------------------------------------------------------------
# Post-Processing (Smoothing)
# -------------------------------------------------------------------

# Smooth CHM using a 3x3 mean filter with the terra package
ker <- matrix(1, 3, 3)
schm <- terra::focal(chm, w = ker, fun = mean, na.rm = TRUE)
plot(schm)

# -------------------------------------------------------------------
# Exercises
# -------------------------------------------------------------------

# E1. Create two CHMs using p2r() and pitfree() at the same resolution and compare.

# E2. Use terra::focal() with w = matrix(1, 5, 5) and fun = max to manipulate a CHM.

# E3. Generate a 10m resolution CHM and discuss its usefulness at that scale.
