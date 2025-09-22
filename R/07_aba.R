# Individual Tree Detection & Segmentation
# https://liamirwin.github.io/SL25_lidRtutorial/07_aba.html

# Environment setup
# -----------------
# Clear environment
rm(list = ls(globalenv()))

# Load packages
library(lidR)
library(sf)
library(terra)
library(dplyr)

# Read in plot centres
plots <- st_read("data/ctg_plots.gpkg", quiet = TRUE) 

# Read in catalog of normalized LAZ tiles
ctg <- catalog("data/ctg_norm")
plot(st_geometry(ctg@data))
plot(st_geometry(plots ), add = TRUE, col = "red")

# Option 1
# Calculate with all-in-one plot_metrics function
plot_mets <- plot_metrics(las = ctg, # use the catalog of normalized LAZ files
                          func = .stdmetrics, # use standard list of metrics
                          geometry = plots, # use plot centres
                          radius = 11.28 # define the radius of the circular plots
)

# Select subset of metrics from the resulting dataframe for model development
plot_mets <- dplyr::select(plot_mets,
                           c(plot_id, ba_ha, sph_ha, # forest attributes
                             merch_vol_ha, zq95, pzabove2, zskew # lidar metrics
                           ))

# Option 2
# Clip normalized LAZ files for each plot location
opt_output_files(ctg) <- "data/plots/las/{plot_id}"
opt_laz_compression(ctg) <- TRUE
# Create circular polygons of 11.28m radius (400m2 area)
plot_buffer <- st_buffer(plots, 11.28)
# Clip normalized LAZ file for each plot
clip_roi(ctg, plot_buffer)

# Create a new catalog referencing the clipped plots we saved
ctg_plot <- catalog("data/plots/las")
opt_independent_files(ctg_plot) <- TRUE # process each plot independently

# Define a metrics function to apply to plots
generate_plot_metrics <- function(chunk){
  # Check if tile is empty
  las <- readLAS(chunk)                  
  if (is.empty(las)) return(NULL)
  # Calculate standard list of metrics (56) built in to lidR for each point cloud
  mets <- cloud_metrics(las, .stdmetrics)
  # Convert output metrics to dataframe (from list)
  mets_df <- as.data.frame(mets)
  # Add plot ID to metrics dataframe
  mets_df$plot_id <- gsub(basename(chunk@files),
                          pattern = ".laz",
                          replacement = "")
  return(mets_df)
}

# Apply our function to each plot in the catalog
plot_mets <- catalog_apply(ctg_plot, generate_plot_metrics)

# Bind the output dataframes into one table
plot_df <- do.call(rbind, plot_mets)

# Rejoin the lidar metrics with the plot vector with attributes
plot_sf <- left_join(plots, plot_df, by = "plot_id")

# Select subset of metrics for model development
plot_mets <- dplyr::select(plot_sf,
                           c(plot_id, ba_ha, sph_ha, # forest attributes
                             merch_vol_ha, zq95, pzabove2, zskew # lidar metrics
                           ))

# Model Development
# Read in plot metrics with forest attributes and lidar metrics calculated for all 162 plots
plot_mets <- read.csv("data/plots/plots_all.csv")

# Generate linear models for each forest attribute using three lidar metrics
lm_vol <- lm(merch_vol_ha ~ zq95 + zskew + pzabove2, data = plot_mets)
lm_ba <- lm(ba_ha ~ zq95 + zskew + pzabove2, data = plot_mets)
lm_sph <- lm(sph_ha ~ zq95 + zskew + pzabove2, data = plot_mets)

# Extract model coefficients
vol_cf <- lm_vol$coefficients
ba_cf <- lm_ba$coefficients
sph_cf <- lm_sph$coefficients


# Create functions from model coefficients that we can apply to metrics rasters
# Function to predict stem volume
vol_lm_r <- function(zq95,zskew,pzabove2){
  vol_cf["(Intercept)"] + (vol_cf["zq95"] * zq95) + (vol_cf["zskew"] * zskew) + (vol_cf["pzabove2"] * pzabove2)
}
# Function to predict basal area
ba_lm_r <- function(zq95,zskew,pzabove2){
  ba_cf["(Intercept)"] + (ba_cf["zq95"] * zq95) + (ba_cf["zskew"] * zskew) + (ba_cf["pzabove2"] * pzabove2)
}
# Function to predict stem density
sph_lm_r <- function(zq95,zskew,pzabove2){
  sph_cf["(Intercept)"] + (sph_cf["zq95"] * zq95) + (sph_cf["zskew"] * zskew) + (sph_cf["pzabove2"] * pzabove2)
}

# Load the full metrics raster
metrics_rast <- rast("data/metrics/fm_mets_20m.tif")
plot(metrics_rast)
# Apply models to generate wall-to-wall forest attribute estimates
# Merchantable Stem Volume
vol_r <- terra::lapp(metrics_rast, fun = vol_lm_r)
plot(vol_r, main = "Merchantable Stem Volume (m3/ha)")
# Basal Area
ba_r <- terra::lapp(metrics_rast, fun = ba_lm_r)
plot(ba_r, main = "Basal Area (m2/ha)")
# Stem Density
sph_r <- terra::lapp(metrics_rast, fun = sph_lm_r)
plot(sph_r, main = "Stem Density (stems/ha)")
