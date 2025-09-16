
# Plot Data Preparation
library(lidR)
library(sf)
library(future)
library(tidyverse)
library(patchwork)
library(terra)

clip_als_plots <- F
calc_plot_metrics <- F
calc_als_metrics <- F
make_vrt <- F
plots <- st_read("data/plots/fm_efi_plots.gpkg") 

# Clip ALS data to plot extents
if(clip_als_plots){
  # LAScatalog of normalized LAZ tiles for entire area
  ctg <- catalog("E:/Misc/FM_montmorency/FM_ALS_2016/input/las/norm")
  # Vector file (points) of plot centre locations (same CRS as LAZ files)
  plots <- st_read("data/plots/fm_efi_plots.gpkg")
  # Create circular polygons of 11.28m radius (200m2 area)
  plots_buffer <- st_buffer(plots, 11.28)
  # Clip normalized LAZ file for each plot
  opt_filter(ctg) <- "-drop_z_below 0"
  opt_progress(ctg) <- TRUE
  plan(multisession, workers = 3L)
  opt_laz_compression(ctg) <- TRUE
  opt_output_files(ctg) <- "data/plots/las/plot_{plot_id}"
  clip_roi(ctg, plots_buffer)
}

if(calc_plot_metrics){
  # Calculate metrics for clipped plots
  ctg_plot <- catalog("data/plots/las")
  opt_independent_files(ctg_plot) <- T # process each plot independently
  opt_progress(ctg_plot) <- TRUE
  
  # Standard metrics
  ctg_mets <- function(chunk){
    las <- readLAS(chunk)                  
    if (is.empty(las)) return(NULL)
    mets <- cloud_metrics(las, .stdmetrics)
    filename <- basename(chunk@files)
    mets$plot_id <- str_replace(tools::file_path_sans_ext(filename), "plot_", "")
    return(mets)
  }
  plan(sequential)
  plot_mets <- catalog_apply(ctg_plot, ctg_mets)
  plot_df <- data.table::rbindlist(plot_mets) %>% relocate(plot_id) %>% filter(plot_id != "NA")
  write.csv(plot_df, "data/plots/plot_metrics.csv", row.names = FALSE)
} else{
  plot_df <- read.csv("data/plots/plot_metrics.csv") %>% mutate(plot_id = as.character(plot_id))
  print("Loaded existing plot metrics as dataframe")
}


if(calc_als_metrics){
  # Create 20x20m pixel metrics for AOI
  ctg <- catalog("E:/Misc/FM_montmorency/FM_ALS_2016/input/las/norm")
  opt_progress(ctg) <- TRUE
  plan(multisession, workers = 4L)
  opt_output_files(ctg) <- "data/fm_metrics_alt/fm_stdmets_{XLEFT}_{YBOTTOM}"
  ctg@output_options$drivers$SpatRaster$param$overwrite <- TRUE
  opt_merge(ctg) <- FALSE
  pixel_metrics(ctg, .stdmetrics, res = 20)
}


plots_full <- left_join(plots, plot_df, by = "plot_id")

# Turn all cols to metric except plot_id and forest attributes
plot_long <- plots_full %>% st_drop_geometry() %>% 
  pivot_longer(cols = -c(plot_id, ba_ha, sph_ha, merch_vol_ha), 
               names_to = "metric", values_to = "value")

mets <- c("zq95","zskew","pzabove2")

plot_trg <- plot_long %>% filter(metric %in% mets)

# Plot facet of zq metrics against ba_ha
ba <- plot_trg %>% ggplot(aes(x = value, y = ba_ha)) +
  geom_point() +
  facet_wrap(~metric, scales = "free_x") +
  labs(x = "Metric value", y = "Basal area (m2/ha)") +
  theme_classic()

sph <- plot_trg %>% ggplot(aes(x = value, y = sph_ha)) +
  geom_point() +
  facet_wrap(~metric, scales = "free_x") +
  labs(x = "Metric value", y = "Stem density (stems/ha)") +
  theme_classic()

vol <- plot_trg %>% ggplot(aes(x = value, y = merch_vol_ha)) +
  geom_point() +
  facet_wrap(~metric, scales = "free_x") +
  labs(x = "Metric value", y = "Merchantable volume (m3/ha)") +
  theme_classic()

ba / sph / vol

set.seed(2025)

plot_wide <- plot_trg %>% pivot_wider(names_from = metric, values_from = value) 

lm_ba <- lm(ba_ha ~ zq95 + zskew + pzabove2, data = plot_wide)
lm_sph <- lm(sph_ha ~ zq95 + zskew + pzabove2, data = plot_wide)
lm_vol <- lm(merch_vol_ha ~ zq95 + zskew + pzabove2, data = plot_wide)

summary(lm_ba)
summary(lm_sph)
summary(lm_vol)


if(make_vrt){
  # Make VRT of all 20x20m metric tiles
  met_vrt <- terra::vrt(x = list.files("data/fm_metrics", pattern = ".tif", full.names = T), 
                        filename = "data/fm_metrics.vrt")
}else{
met_vrt <- rast("data/fm_metrics.vrt")
print("Loaded existing VRT of metrics")
}
x = list.files("data/fm_metrics", pattern = ".tif", full.names = T)
r <- rast(x[1])

names(met_vrt) <- names(r)
library(tidyterra)
sub_met <- met_vrt %>% select(all_of(mets))

bdy <- st_read("data/fm_boundary.gpkg") %>% st_transform(st_crs(met_vrt)) %>% vect()

bdy_met <- sub_met %>% terra::crop(bdy) %>% terra::mask(bdy) %>% 
  mutate(zq95 = clamp(zq95, lower = 0, upper = 30),
         zskew = clamp(zskew, lower = -1, upper = 10),
         pzabove2 = clamp(pzabove2, lower = 0, upper = 100))

bdy_met <- bdy_met 
writeRaster(bdy_met, "data/metrics/fm_mets_20m.tif")

p1 <- bdy_met$zq95 %>% autoplot()+ theme_classic() + labs(fill = "95th percentile of height (m)")
p2 <- bdy_met$pzabove2 %>% autoplot() + theme_classic() + labs(fill = "Canopy Cover - Percentage of points above 2m (%)")
p3 <- bdy_met$zskew %>% autoplot()+ theme_classic()+ labs(fill = "Skewness of height distribution")





ctg_mets <- function(chunk){
  las <- readLAS(chunk)                  
  if (is.empty(las)) return(NULL)
  mets <- cloud_metrics(las, .stdmetrics)
  filename <- basename(chunk@files)
  mets$plot_id <- str_replace(tools::file_path_sans_ext(filename), "plot_", "")
  return(mets)
}
# Metrics subset





# boundary

# 9 Tile subset (for tutorial)


# Then swap in large 20x20m pixel metrics raster (we've generated for them)


library(lidR)
# Add noise to the raw laz file
las <- readLAS('data/raw/fm_4km.laz')
las_noise <- las
# add some noise
set.seed(1337)
# add random noise to 1000 random points
id = round(runif(1000, 0, npoints(las)))
# generate random error points between -50 and 50 m
err = runif(1000, -50, 50)
# add error to Z values
las_noise$Z[id] = las_noise$Z[id] + err

writeLAS(las_noise, "data/raw/fm_all.laz")


















