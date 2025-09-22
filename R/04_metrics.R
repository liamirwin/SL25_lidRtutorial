# Lidar Summary Metrics
# https://liamirwin.github.io/SL25_lidRtutorial/04_metrics.html

# Environment setup
# -----------------
# Clear workspace and load required packages
rm(list = ls(globalenv()))
library(lidR)
library(terra)
library(lidRmetrics) # Make sure you have this installed via Github (see tutorial)

# -------------------------------------------------------------------
# Basic Pixel Metrics
# -------------------------------------------------------------------

# Load the normalized lidar data
las <- readLAS(files = "data/fm_norm.laz")

# Compute mean return height at 10m resolution
hmean <- pixel_metrics(las = las, func = ~mean(Z), res = 10)
plot(hmean)

# Compute max return height at 10m resolution
hmax <- pixel_metrics(las = las, func = ~max(Z), res = 10)
plot(hmax)

# Compute several metrics at once using a list
metrics <- pixel_metrics(las = las, func = ~list(hmax = max(Z), hmean = mean(Z)), res = 10)
plot(metrics)

# Simplify computing metrics with predefined sets of metrics
metrics <- pixel_metrics(las = las, func = .stdmetrics_z, res = 10)
plot(metrics)

# Plot a specific metric from the predefined set
plot(metrics, "zsd")

# -------------------------------------------------------------------
# Advanced Metrics (lidRmetrics package)
# -------------------------------------------------------------------

# Canopy cover: proportion of returns above 2m
cc_metrics <- pixel_metrics(las, func = ~metrics_percabove(z = Z, threshold = 2, zmin = 0), res = 10)
plot(cc_metrics)

# Leaf area density profiles (LAD)
lad_metrics <- pixel_metrics(las, ~metrics_lad(z = Z), res = 10)
plot(lad_metrics)
plot(lad_metrics, "lad_cv")

# Dispersion and vertical complexity
disp_metrics <- pixel_metrics(las, ~metrics_dispersion(z = Z, zmax = 40), res = 10)
plot(disp_metrics)
plot(disp_metrics, "CRR")
plot(disp_metrics, "VCI")

# Generate a user-defined function to compute weighted mean between two attributes
f <- function(x, weight) { sum(x*weight)/sum(weight) }

# Compute weighted mean of height (Z) as a function of return intensity
user_metric <- pixel_metrics(las = las, func = ~f(Z, Intensity), res = 10)

# Visualize the output
plot(user_metric)

# -------------------------------------------------------------------
# Exercises
# -------------------------------------------------------------------

# E1. Generate another metric set from the lidRmetrics package (voxel metrics may be slow).

# E2. Map ground return density at 5m resolution. Hint: filter = "-keep_class 2" and calculate points/m².

# E3. Estimate biomass using B = 0.5 * mean(Z) + 0.9 * 90th percentile(Z) on first returns only and map the result.
