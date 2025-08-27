# Digital Terrain Models
# https://liamirwin.github.io/LPS_lidRtutorial/02_dtm.html

# Environment setup
# -----------------
# Clear current workspace and load required packages
rm(list = ls(globalenv()))
library(lidR)

# -------------------------------------------------------------------
# Digital Terrain Model (DTM) Generation
# -------------------------------------------------------------------

# Load pre-classified lidar data
las <- readLAS(files = "data/zrh_class.laz")

# Visualize raw lidar point cloud
plot(las)
plot(las, color = "Classification")

# -------------------------------------------------------------------
# Triangulation Algorithm: tin()
# -------------------------------------------------------------------

# Generate DTM using TIN algorithm at 1 m resolution
dtm_tin <- rasterize_terrain(las = las, res = 1, algorithm = tin())

# Visualize DTM in 3D
plot_dtm3d(dtm_tin)

# Overlay DTM with non-ground lidar points
las_ng <- filter_poi(las = las, Classification != 2L)
x <- plot(las_ng)
add_dtm3d(x, dtm_tin)

# -------------------------------------------------------------------
# Inverse-Distance Weighting Algorithm: knnidw()
# -------------------------------------------------------------------

# Generate DTM using IDW algorithm at 1 m resolution
dtm_idw <- rasterize_terrain(las = las, res = 1, algorithm = knnidw())

# Visualize IDW-based DTM in 3D
plot_dtm3d(dtm_idw)

# -------------------------------------------------------------------
# Height Normalization
# -------------------------------------------------------------------

# Normalize using pre-computed TIN DTM
nlas_dtm <- normalize_height(las = las, algorithm = dtm_tin)
plot(nlas_dtm)

# Normalize on-the-fly using TIN algorithm 
nlas_tin <- normalize_height(las = las, algorithm = tin())
plot(nlas_tin)

# -------------------------------------------------------------------
# Exercises
# -------------------------------------------------------------------

# E1. Compute two DTMs at different spatial resolutions and plot both.

# E2. Use plot_dtm3d() to visualize and interact with your DTMs.
