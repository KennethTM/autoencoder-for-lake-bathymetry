#Figures for manuscript

source("libs_and_funcs.R")

#Figure 1
#Elevation map of Denmark and lakes

dem_coarse <- getData(name = "alt", path = "data/", country="DNK")
dem_course_crop <- trim(crop(dem_coarse, extent(c(8, 14, 54.5, 57.8))))
dem_utm <- projectRaster(dem_course_crop, crs = dk_epsg, method="bilinear")
dem_df <- as.data.frame(dem_utm, xy=TRUE)

lakes <- read_csv("data/lakes_summary_partition.csv")
lakes_sf <- lakes |> 
  st_as_sf(crs=dk_epsg, coords=c("x", "y"))

figure_1 <- ggplot()+
  geom_raster(data=dem_df, aes(x, y, fill=DNK_msk_alt))+
  #scale_fill_viridis_c(option = "E", na.value = NA, name="Elevation (m)")+
  scale_fill_continuous_sequential(palette="Terrain 2", rev=FALSE, na.value = NA, name="Elevation (m)")+
  geom_sf(data=lakes_sf, col="black", shape=1)+
  xlab("Longitude")+
  ylab("Latitude")+
  theme(legend.position = "bottom")+
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = unit(60, "mm")))

ggsave("figures/figure_1.png", figure_1, width = 84, height = 110, units = "mm")

#Table 1
#Lake summary statistics
lakes <- read_csv("data/lakes_summary_partition.csv")

lakes |> 
  mutate(area_km2 = area*10^-6) |> #area to km2
  dplyr::select(area_km2, elev, mean_depth, max_depth) |> 
  gather(variable, value) |> 
  na.omit() |> #lake 89 missing values??, 1 lake with negative mean depth, remove lakes with zmax < 1
  group_by(variable) |> 
  summarise(min = min(value),
            q25 = quantile(value, 0.25),
            median = median(value),
            mean = mean(value),
            q75 = quantile(value, 0.75),
            max = max(value)) |> 
  mutate_if(is.numeric, ~round(.x, digits=1))

#Figure 2
target <- readPNG("data/target.png")
mask <- readPNG("data/mask.png")
hat <- readPNG("data/hat.png")

diff <- target - hat
diff[mask == 0] = NA

target_df <- as.data.frame(raster(target), xy=TRUE)
mask_df <- as.data.frame(raster(mask), xy=TRUE)
diff_df <- as.data.frame(raster(diff), xy=TRUE)

fig_target <- ggplot()+
  geom_raster(data=target_df, aes(x, y, fill=layer), show.legend = FALSE)+
  theme_void()+
  scale_fill_continuous_sequential(palette="Terrain 2", rev=FALSE, na.value = NA)+
  ggtitle("Ground truth")+
  coord_equal()

fig_target_masked <- fig_target+
  geom_raster(data=mask_df, aes(x, y, alpha=factor(layer)), show.legend = FALSE, fill="black")+
  scale_alpha_manual(values=c(0, 0.5))+
  ggtitle("Ground truth with mask")+
  coord_equal()

fig_diff <- ggplot()+
  geom_raster(data=diff_df, aes(x, y, fill=layer), show.legend = FALSE)+
  theme_void()+
  scale_fill_continuous_diverging(rev=FALSE, na.value = NA, palette="Blue-Red 3")+
  ggtitle("Ground truth - predicted")+
  coord_equal()

figure_2 <- fig_target + fig_target_masked + fig_diff & theme(plot.title = element_text(hjust=0.5))

ggsave("figures/figure_2.png", figure_2, width = 174, height = 70, units = "mm")
