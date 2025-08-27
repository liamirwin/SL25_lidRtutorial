# Regions of Interest
# https://liamirwin.github.io/LPS_lidRtutorial/supplemental/S1_roi.html

# Environment setup
# -----------------
# Clear workspace and load required packages
rm(list = ls(globalenv()))
library(lidR)
library(sf)

# -------------------------------------------------------------------
# Simple Geometries
# -------------------------------------------------------------------

# Load LiDAR data and inspect header
las <- readLAS(files = 'data/zrh_norm.laz')
las@header
las@header$`Number of point records`

# Select circular area
x <- 2670592
y <- 1258890
circle <- clip_circle(las = las, xcenter = x, ycenter = y, radius = 30)
circle
circle@header$`Number of point records`
# Plot circular area
plot(circle)
plot(circle, bg = 'white')

# Select rectangular area
rect <- clip_rectangle(las = las, xleft = x, ybottom = y, xright = x + 40, ytop = y + 30)
# Plot rectangular area
plot(rect)
plot(rect, bg = 'white')

# Select multiple random circular areas
x_random <- runif(2, x, x)
y_random <- runif(2, 1258840, 1258890)
plots <- clip_circle(las = las, xcenter = x_random, ycenter = y_random, radius = 10)
# Plot each area
plot(plots[[1]])
plot(plots[[1]], bg = 'white')
plot(plots[[2]])
plot(plots[[2]], bg = 'white')

# -------------------------------------------------------------------
# Complex Geometries from Geopackage
# -------------------------------------------------------------------

# Load ROI from geopackage
stand_bdy <- sf::st_read(dsn = 'data/roi/roi.gpkg', quiet = TRUE)
# Plot LiDAR header and boundary
plot(las@header, map = FALSE)
plot(stand_bdy, add = TRUE, col = '#08B5FF39')
# Extract ROI using clip_roi()
stand <- clip_roi(las = las, geometry = stand_bdy)
# Plot extracted ROI
plot(stand)
plot(stand, bg = 'white')

# -------------------------------------------------------------------
# Catalog ROI Clipping
# -------------------------------------------------------------------

# Read catalog
ctg <- catalog('data/ctg_norm')
# Define coordinate groups
x_group <- c(2670578, 2671234, 2671499, 2671755, 2671122)
y_group <- c(1258601, 1259050, 1259450, 1259900, 1258750)
# Plot catalog and points
plot(ctg)
points(x_group, y_group)
# Clip circles on catalog
rois <- clip_circle(las = ctg, xcenter = x_group, ycenter = y_group, radius = 30)
# Plot some results
plot(rois[[1]])
plot(rois[[1]], bg = 'white')
plot(rois[[3]])
plot(rois[[3]], bg = 'white')

# -------------------------------------------------------------------
# Validation
# -------------------------------------------------------------------

# Validate clipped LAS objects
las_check(rois[[1]])
las_check(rois[[3]])

# -------------------------------------------------------------------
# Independent LAS as Catalog
# -------------------------------------------------------------------

# Read single LAS file as catalog
ctg_single <- readLAScatalog(folder = 'data/zrh_norm.laz')
opt_output_files(ctg_single)   <- paste0(tempdir(), '/{XCENTER}_{XCENTER}')
opt_laz_compression(ctg_single) <- TRUE
# Generate random ROIs
x_i <- runif(4, min = ctg_single$Min.X, max = ctg_single$Max.X)
y_i <- runif(4, min = ctg_single$Min.Y, max = ctg_single$Max.Y)
rois_i <- clip_circle(las = ctg_single, xcenter = x_i, ycenter = y_i, radius = 10)

# -------------------------------------------------------------------
# Exercises
# -------------------------------------------------------------------

# E1. Use sf::st_read() to load 'MixedEucaNatPlot.shp' and plot over the LiDAR header.

# E2. Clip 5 plots with a radius of 11.3 m around random locations.

# E3. Clip a transect from A c(203850, 7358950) to B c(203950, 7359000).

# E4. Clip the same transect but reorient it (hint: clip_transect()).
