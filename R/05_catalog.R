# LAScatalog
# https://liamirwin.github.io/SL25_lidRtutorial/05_catalog.html

# Environment setup
# -----------------
# Clear workspace and load required packages
rm(list = ls(globalenv()))
library(lidR)
library(sf)

# -------------------------------------------------------------------
# Reading and Inspecting a LAScatalog
# -------------------------------------------------------------------

# Read catalog of files
ctg <- readLAScatalog(folder = "data/ctg_norm")

# Inspect catalog summary
ctg

# Visualize catalog extents
plot(ctg, chunk = TRUE)

# Optional interactive plot with mapview (if installed)
plot(ctg, map = TRUE)

# -------------------------------------------------------------------
# Indexing for Efficient Processing
# -------------------------------------------------------------------

# check if files have .lax
is.indexed(ctg)
# generate index files
lidR:::catalog_laxindex(ctg)
# check if files have .lax
is.indexed(ctg)


# -------------------------------------------------------------------
# Generating CHM from a Catalog
# -------------------------------------------------------------------

# Generate CHM
chm <- rasterize_canopy(las = ctg,
                        res = 1,
                        algorithm = p2r(subcircle = 0.15))
plot(chm)

# -------------------------------------------------------------------
# Catalog Processing Options
# -------------------------------------------------------------------

# Setting options and re-rasterizing the CHM
opt_filter(ctg) <- "-drop_z_below 0 -drop_z_above 50"
opt_select(ctg) <- "xyz"
chm <- rasterize_canopy(las = ctg, res = 1, algorithm = p2r(subcircle = 0.15))
plot(chm)

# -------------------------------------------------------------------
# Pixel Metrics from a Catalog
# -------------------------------------------------------------------

# Generate pixel-based metrics
max_z <- pixel_metrics(las = ctg, func = ~mean(Z), res = 20)
plot(max_z)

# Compute mean Z using first returns only
opt_filter(ctg) <- "-drop_z_below 0 -drop_z_above 50 -keep_first"
max_z <- pixel_metrics(las = ctg, func = ~mean(Z), res = 20)
plot(max_z)

# Specify options
opt_select(ctg) <- "xyz"
opt_chunk_size(ctg) <- 500
opt_chunk_buffer(ctg) <- 10
opt_progress(ctg) <- TRUE

# Visualize and summarize the catalog chunks
plot(ctg, chunk = TRUE)
summary(ctg)

# -------------------------------------------------------------------
# Parallel Processing
# -------------------------------------------------------------------

# Load future for parallel processing of tiles
library(future)

t_start <- Sys.time() # start timer

# Set to Process on single core (default)
plan(sequential)

# Generate a point density raster (points per square metre)
dens_seq <- rasterize_density(ctg, res = 10)

plot(dens_seq)

time_diff_secs <- difftime(Sys.time(), t_start, units = "secs")
print(paste("Processing time:", time_diff_secs, "seconds"))

t_start <- Sys.time() # start timer
# Process on multi-core with three workers
plan(multisession, workers = 3L)

# Generate the same density raster, but in parallel
dens_par <- rasterize_density(ctg, res = 10)

plot(dens_par)

time_diff_secs <- difftime(Sys.time(), t_start, units = "secs")
print(paste("Processing time:", time_diff_secs, "seconds"))

# Back to single core
plan(sequential)


# -------------------------------------------------------------------
# Exercises
# -------------------------------------------------------------------

# E1. Compute another set of metrics from lidRmetrics on the catalog (avoid voxel metrics).
# Use: `("data/ctg_norm")`

# E2. Read the non-normalized catalog with only first returns. 
# Use: `("data/ctg_class")`

# E3. Generate a 1m DTM for the catalog using only first returns.