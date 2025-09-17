# Individual Tree Detection & Segmentation
# https://liamirwin.github.io/LPS_lidRtutorial/08_its.html

# Environment setup
# -----------------
# Clear workspace and install/load required packages
rm(list = ls(globalenv()))
if (!requireNamespace("concaveman", quietly = TRUE)) install.packages("concaveman")
library(concaveman)
library(lidR)
library(sf)
library(terra)

# Read in LiDAR file and set some color palettes
las <- readLAS("data/fm_norm.laz")

col <- height.colors(50)
col1 <- pastel.colors(900)

# -------------------------------------------------------------------
# CHM-Based Segmentation
# -------------------------------------------------------------------

# Generate CHM with p2r percentile algorithm
chm <- rasterize_canopy(las = las, res = 0.5, algorithm = p2r(0.15))
plot(chm, col = col)

# Smooth CHM with 3x3 median filter
kernel <- matrix(1, 3, 3)
schm <- terra::focal(chm, w = kernel, fun = median, na.rm = TRUE)
plot(schm, col = col)

# Detect tree tops on smoothed CHM using local maxima filtering
ttops <- locate_trees(las = schm, algorithm = lmf(ws = 2.5))
plot(chm, col = col)
plot(ttops, col = "black", add = TRUE, cex = 0.5)

# Segment trees using Dalponte et al. (2016) algorithm
las <- segment_trees(las = las, algorithm = dalponte2016(chm = schm, treetops = ttops))
length(unique(las$treeID)[!is.na(las$treeID)])
tree_ids <- unique(las$treeID)
plot(las, color = "treeID", bg = "white")

# Extract and visualize individual trees
id_1 <- sample(tree_ids, 1)
id_2 <- sample(tree_ids, 2)

# Select trees by ID
tree1 <- filter_poi(las = las, treeID == id_1)
tree2 <- filter_poi(las = las, treeID == id_2)

plot(tree1, size = 4, bg = "white")
plot(tree2, size = 4, bg = "white")

# -------------------------------------------------------------------
# Raster-Based ITS
# -------------------------------------------------------------------

# Generate tree delineation raster from CHM
trees <- dalponte2016(chm = chm, treetops = ttops)()
plot(trees, col = col1)
plot(ttops, add = TRUE, cex = 0.5)

# -------------------------------------------------------------------
# Point-Cloud ITS (No CHM)
# -------------------------------------------------------------------

# Detect tree tops directly on point cloud
ttops <- locate_trees(las = las, algorithm = lmf(ws = 3, hmin = 5))
x <- plot(las, bg = "white")
add_treetops3d(x = x, ttops = ttops, radius = 0.5)

# Segment trees using Li et al. (2012) algorithm
las <- segment_trees(las = las, algorithm = li2012())
plot(las, color = "treeID", bg = "white")

# -------------------------------------------------------------------
# Crown Metrics Extraction
# -------------------------------------------------------------------

# Example: count points per crown
metrics <- crown_metrics(las = las, func = ~list(n = length(Z)))
metrics
plot(metrics["n"], cex = 0.8)

# User defined function for area calculation
f <- function(x, y) {
  # Get xy for tree
  coords <- cbind(x, y)
  
  # Convex hull
  ch <- chull(coords)
  
  # Close coordinates
  ch <- c(ch, ch[1])
  ch_coords <- coords[ch, ]
  
  # Generate polygon
  p <- sf::st_polygon(list(ch_coords))
  
  #calculate area
  area <- sf::st_area(p)
  
  return(list(A = area))
}

# Apply user-defined function
metrics <- crown_metrics(las = las, func = ~f(X, Y))
metrics
plot(metrics["A"], cex = 0.8)

# Predefined standard tree metrics
metrics <- crown_metrics(las = las, func = .stdtreemetrics)
metrics

# Visualize individual metrics
plot(x = metrics["convhull_area"], cex = 0.8)
plot(x = metrics["Z"], cex = 0.8)

# Delineating Crowns
cvx_hulls <- crown_metrics(las = las, func = .stdtreemetrics, geom = 'convex')
cvx_hulls

plot(cvx_hulls)
plot(ttops, add = TRUE, cex = 0.5)

# Visualize individual metrics based on values
plot(x = cvx_hulls["convhull_area"])
plot(x = cvx_hulls["Z"])

# -------------------------------------------------------------------
# ITS with LAScatalog
# -------------------------------------------------------------------

# Load catalog
ctg <- catalog('data/ctg_norm')

# Set catalog options
opt_filter(ctg) <- "-drop_z_below 0 -drop_z_above 50"
opt_select(ctg) <- "xyz"
opt_chunk_size(ctg) <- 500
opt_chunk_buffer(ctg) <- 10
opt_progress(ctg) <- TRUE

# Explicitly tell R to use the is.empty function from the lidR package - avoid terra error
is.empty <- lidR::is.empty

# Detect treetops and plot
ttops <- locate_trees(las = ctg, algorithm = lmf(ws = 3, hmin = 10))
chm <- rasterize_canopy(ctg, algorithm = p2r(), res = 1)
plot(chm)
plot(ttops, add = TRUE, cex = 0.1, col = "red")
