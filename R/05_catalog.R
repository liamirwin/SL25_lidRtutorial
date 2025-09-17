# LAScatalog
# https://liamirwin.github.io/LPS_lidRtutorial/05_engine.html

# Environment setup
# -----------------
# Clear workspace and load required packages
rm(list = ls(globalenv()))
library(lidR)
library(sf)

# -------------------------------------------------------------------
# Reading and Inspecting a LAScatalog
# -------------------------------------------------------------------

# Read catalog of LAS/LAZ files
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

# Check if catalog is indexed
is.indexed(ctg)

# Generate index files (.lax)
lidR:::catalog_laxindex(ctg)

# Confirm indexing
is.indexed(ctg)

# -------------------------------------------------------------------
# Generating CHM from a Catalog
# -------------------------------------------------------------------

# Create CHM at 1m resolution using p2r with subcircle
chm <- rasterize_canopy(las = ctg, res = 1, algorithm = p2r(subcircle = 0.15))
plot(chm)

# -------------------------------------------------------------------
# Catalog Processing Options
# -------------------------------------------------------------------

# Apply filters and select variables
opt_filter(ctg) <- "-drop_z_below 0 -drop_z_above 50"
opt_select(ctg) <- "xyz"

# Re-generate CHM with new options
chm_filtered <- rasterize_canopy(las = ctg, res = 1, algorithm = p2r(subcircle = 0.15))
plot(chm_filtered)

# -------------------------------------------------------------------
# Pixel Metrics from a Catalog
# -------------------------------------------------------------------

# Compute mean Z at 20m resolution
max_z <- pixel_metrics(las = ctg, func = ~mean(Z), res = 20)
plot(max_z)

# Compute mean Z using first returns only
opt_filter(ctg) <- "-drop_z_below 0 -drop_z_above 50 -keep_first"
first_z <- pixel_metrics(las = ctg, func = ~mean(Z), res = 20)
plot(first_z)

# -------------------------------------------------------------------
# Parallel Processing
# -------------------------------------------------------------------

# Load future for parallel processing of tiles
library(future)

# Specify chunk options
opt_select(ctg) <- "xyz" # Keep XYZ coordinates
opt_chunk_size(ctg) <- 500 # Set processing size to 500m (same as tile)
opt_chunk_buffer(ctg) <- 10 # Add buffer (done by default too)
opt_progress(ctg) <- TRUE # Show progress

# Plot chunks and summary
plot(ctg, chunk = TRUE)
summary(ctg)

# Single-core processing
plan(sequential)
dens_seq <- rasterize_density(ctg, res = 10)
plot(dens_seq)

# Multi-core processing (3 workers)
plan(multisession, workers = 3L)
dens_par <- rasterize_density(ctg, res = 10)
plot(dens_par)

# Revert to single core
plan(sequential)

# -------------------------------------------------------------------
# Exercises
# -------------------------------------------------------------------

# E1. Compute another set of metrics from lidRmetrics on the catalog (avoid voxel metrics).
# Use: `("data/ctg_norm")`

# E2. Read the non-normalized catalog with only first returns. 
# Use: `("data/ctg_class")`

# E3. Generate a 1m DTM for the catalog using only first returns.