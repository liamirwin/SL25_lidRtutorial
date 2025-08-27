# Individual Tree Detection & Segmentation
# https://liamirwin.github.io/LPS_lidRtutorial/supplemental/S2_its.html

# Environment setup
# -----------------
# Clear workspace and install/load required packages
rm(list = ls(globalenv()))
if (!requireNamespace("concaveman", quietly = TRUE)) install.packages("concaveman")
library(concaveman)
library(lidR)
library(sf)
library(terra)

# Load LiDAR data and set color palettes
las <- readLAS(files = "data/zrh_norm.laz")
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
plot(las, color = "treeID", bg = "white")

# Extract and visualize individual trees
tree25  <- filter_poi(las = las, treeID ==  25)
plot(tree25, size = 4, bg = "white")
tree125 <- filter_poi(las = las, treeID == 125)
plot(tree125, size = 4, bg = "white")

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
ttops2 <- locate_trees(las = las, algorithm = lmf(ws = 3, hmin = 5))
x <- plot(las, bg = "white")
add_treetops3d(x = x, ttops = ttops2, radius = 0.5)

# Segment trees using Li et al. (2012) algorithm
las <- segment_trees(las = las, algorithm = li2012())
plot(las, color = "treeID", bg = "white")

# -------------------------------------------------------------------
# Crown Metrics Extraction
# -------------------------------------------------------------------

# Example: count points per crown
metrics_n <- crown_metrics(las = las, func = ~list(n = length(Z)))
plot(metrics_n["n"], cex = 0.8)

# Convex hull area metric
f_area <- function(x, y) {
  coords <- cbind(x, y)
  ch     <- chull(coords)
  ch     <- c(ch, ch[1])
  poly   <- sf::st_polygon(list(coords[ch, ]))
  list(A = sf::st_area(poly))
}
metrics_A <- crown_metrics(las = las, func = ~f_area(X, Y))
plot(metrics_A["A"], cex = 0.8)

# Predefined standard tree metrics
metrics_std <- crown_metrics(las = las, func = .stdtreemetrics)
plot(metrics_std["convhull_area"], cex = 0.8)
plot(metrics_std["Z"], cex = 0.8)

# -------------------------------------------------------------------
# ITS with LAScatalog
# -------------------------------------------------------------------

# Configure catalog for ITD
ctg <- catalog("data/ctg_norm")
opt_filter(ctg)      <- "-drop_z_below 0 -drop_z_above 50"
opt_select(ctg)      <- "xyz"
opt_chunk_size(ctg)  <- 500
opt_chunk_buffer(ctg)<- 10
opt_progress(ctg)    <- TRUE
is.empty            <- lidR::is.empty

# Detect treetops and generate CHM in catalog
ttops_cat <- locate_trees(las = ctg, algorithm = lmf(ws = 3, hmin = 10))
chm_cat   <- rasterize_canopy(las = ctg, res = 1, algorithm = p2r())
plot(chm_cat)
plot(ttops_cat, add = TRUE, cex = 0.1, col = "red")
