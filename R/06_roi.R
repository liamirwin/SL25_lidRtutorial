# Regions of Interest
# https://liamirwin.github.io/SL25_lidRtutorial/06_roi.html

# Environment setup
# -----------------
# Clear workspace and load required packages
rm(list = ls(globalenv()))
library(lidR)
library(sf)
library(terra)
library(dplyr)

# -------------------------------------------------------------------
# Simple Geometries
# -------------------------------------------------------------------

# Load LiDAR data and inspect header
las <- readLAS(files = 'data/fm_norm.laz')
# Inspect the header and the number of point records
las@header
las@header$`Number of point records`


# Establish coordinates
x <- 254250
y <- 5235510

# Select a circular area
circle <- clip_circle(las = las, xcenter = x, ycenter = y, radius = 30)

# Inspect the circular area and the number of point records
circle
circle@header$`Number of point records`

# Plot circular area
plot(circle)

# Select rectangular area
rect <- clip_rectangle(las = las, xleft = x, ybottom = y, xright = x + 40, ytop = y + 30)

# Plot rectangular area
plot(rect)

# Select multiple random circular areas
x <- runif(2, x, x)
y <- runif(2, 5235500, 5235700)

plots <- clip_circle(las = las, xcenter = x, ycenter = y, radius = 10)

# Plot each area
plot(plots[[1]])
plot(plots[[2]])

# -------------------------------------------------------------------
# Complex Geometries from Geopackage
# -------------------------------------------------------------------

# Load the geopackage using sf
stand_bdy <- sf::st_read(dsn = "data/roi/roi.gpkg", quiet = TRUE)

# Plot the lidar header information without the map
plot(las@header, map = FALSE)

# Plot the stand boundary areas on top of the lidar header plot
plot(stand_bdy, add = TRUE, col = "#08B5FF39")

# Extract points within the stand boundary using clip_roi()
stand <- clip_roi(las = las, geometry = stand_bdy)

# Plot extracted ROI
plot(stand)

# -------------------------------------------------------------------
# Catalog ROI Clipping
# -------------------------------------------------------------------

# Read catalog
ctg <- catalog("data/ctg_norm")

# Set coordinate groups
x <- c(254000, 254250, 254500, 254750, 254780)
y <- c(5235000, 5235250, 5235500, 5235750, 5235800)

# Visualize coordinate groups
plot(ctg)
points(x, y)

# Clip 30 m plots
rois <- clip_circle(las = ctg, xcenter = x, ycenter = y, radius = 30)

# Plot some results
plot(rois[[1]])
plot(rois[[3]])

# -------------------------------------------------------------------
# Validation
# -------------------------------------------------------------------

# Validate clipped LAS objects
las_check(rois[[1]])
las_check(rois[[3]])

# -------------------------------------------------------------------
# Independent LAS as Catalog
# -------------------------------------------------------------------

# Read single file as catalog
ctg <- readLAScatalog(folder = "data/fm_norm.laz")

# Set options for output files
opt_output_files(ctg) <- paste0(tempdir(),"/{XCENTER}_{XCENTER}")

# Write file as .laz
opt_laz_compression(ctg) <- TRUE

# Get random plot locations and clip
x <- runif(n = 4, min = ctg$Min.X, max = ctg$Max.X)
y <- runif(n = 4, min = ctg$Min.Y, max = ctg$Max.Y)
rois <- clip_circle(las = ctg, xcenter = x, ycenter = y, radius = 10)

# Read catalog of plots
ctg_plots <- readLAScatalog(tempdir())

# Set independent files option
opt_independent_files(ctg_plots) <- TRUE
opt_output_files(ctg_plots) <- paste0(tempdir(),"/{XCENTER}_{XCENTER}")

# Generate plot-level terrain models
rasterize_terrain(las = ctg_plots, res = 1, algorithm = tin())


# Check files
path <- paste0(tempdir())
file_list <- list.files(path, full.names = TRUE)
file <- file_list[grep("\\.tif$", file_list)][[1]]

# plot dtm
plot(terra::rast(file))
