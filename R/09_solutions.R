# Exercise Solutions
# https://liamirwin.github.io/LPS_lidRtutorial/06_solutions.html

# Environment setup
# -----------------
# Clear workspace and load required packages
rm(list = ls(globalenv()))
library(sf)
library(terra)
library(lidR)
library(lidRmetrics)

# -------------------------------------------------------------------
# 1 - LAS Exercises
# -------------------------------------------------------------------

# E1: Plot the point cloud colored by ReturnNumber with axis and legend
las <- readLAS(files = "data/zrh_norm.laz")
plot(las, color = "ReturnNumber", axis = TRUE, legend = TRUE)

# E2: Filter returns with Intensity > 50 and plot
las <- readLAS(files = "data/zrh_norm.laz")
i_50 <- filter_poi(las = las, Intensity > 50)
plot(i_50)

# E3: Read LAS with only xyz and intensity attributes
las_xyz_i <- readLAS(files = "data/zrh_norm.laz", select = "xyzi")

# -------------------------------------------------------------------
# 2 - DTM Exercises
# -------------------------------------------------------------------

las <- readLAS(files = "data/zrh_class.laz")
# E1: Compute DTMs at 5m and 10m resolution
dtm_5 <- rasterize_terrain(las = las, res = 5, algorithm = tin())
dtm_10 <- rasterize_terrain(las = las, res = 10, algorithm = tin())
plot(dtm_5)
plot(dtm_10)

# E2: Visualize DTM in 3D
plot_dtm3d(dtm_5)

# -------------------------------------------------------------------
# 3 - CHM Exercises
# -------------------------------------------------------------------

las <- readLAS(files = "data/zrh_norm.laz")
# E1: Generate CHMs with p2r() and pitfree() at 2m resolution
chm_p2r <- rasterize_canopy(las = las, res = 2, algorithm = p2r())
thresholds <- c(0, 5, 10, 20, 25, 30)
max_edge <- c(0, 1.35)
chm_pitfree <- rasterize_canopy(las = las, res = 2, algorithm = pitfree(thresholds, max_edge))
plot(chm_p2r)
plot(chm_pitfree)

# E2: Smooth CHM using a 5x5 max filter
schm_max <- terra::focal(chm_pitfree, w = matrix(1, 5, 5), fun = max, na.rm = TRUE)
plot(schm_max)

# E3: Create a 10m resolution CHM
chm_10 <- rasterize_canopy(las = las, res = 10, algorithm = p2r())
plot(chm_10)

# -------------------------------------------------------------------
# 4 - Metrics Exercises
# -------------------------------------------------------------------

las <- readLAS(files = "data/zrh_norm.laz")
# E1: Generate percentile metrics from lidRmetrics
percentiles <- pixel_metrics(las, func = ~metrics_percentiles(z = Z), res = 20)
plot(percentiles)

# E2: Map ground return density at 5m resolution
las_gnd <- readLAS(files = "data/zrh_norm.laz", filter = "-keep_class 2")
gnd_density <- pixel_metrics(las_gnd, func = ~length(Z)/25, res = 5)
plot(gnd_density)

# E3: Map biomass using first returns only
las_first <- readLAS(files = "data/zrh_norm.laz")
biomass <- pixel_metrics(las_first,
                         func = ~0.5 * mean(Z) + 0.9 * quantile(Z, probs = 0.9),
                         res = 10,
                         filter = ~ReturnNumber == 1L)
plot(biomass)

# -------------------------------------------------------------------
# 5 - LAScatalog Exercises
# -------------------------------------------------------------------

# E1: Compute dispersion metrics from lidRmetrics on catalog
ctg_norm <- readLAScatalog(folder = "data/ctg_norm")
dispersion <- pixel_metrics(ctg_norm, func = ~metrics_dispersion(z = Z, dz = 2, zmax = 30), res = 20)
plot(dispersion)

# E2: Read non-normalized catalog with only first returns
ctg_class <- readLAScatalog(folder = "data/ctg_class")
opt_filter(ctg_class) <- "-keep_first -keep_class 2"

# E3: Generate 1m DTM for catalog using first returns
dtm_first <- rasterize_terrain(ctg_class, res = 1, algorithm = tin())
plot(dtm_first)
