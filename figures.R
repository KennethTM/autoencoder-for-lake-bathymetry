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

table_1 <- lakes |> 
  mutate(area_km2 = area*10^-4) |> #area to ha
  dplyr::select(area_km2, elev, mean_depth, max_depth) |> 
  gather(variable, value) |> 
  group_by(variable) |> 
  summarise(min = min(value),
            q25 = quantile(value, 0.25),
            median = median(value),
            mean = mean(value),
            q75 = quantile(value, 0.75),
            max = max(value)) |> 
  mutate_if(is.numeric, ~round(.x, digits=1))

write_csv(table_1, "figures/table_1.csv")

#Figure 2
dem_path <- paste0(data_path, "dtm_10m.tif")
dem <- raster(dem_path)

lake <- 22 #Borre Sø
lake_mask <- raster(paste0("data/buffer_33_percent/lakes_mask/lake_", lake, ".tif"))
lake_mask_vect <- st_as_sf(rasterToPolygons(lake_mask, fun=function(x){x==1}, dissolve = TRUE))
lake_33 <- raster(paste0("data/buffer_33_percent/lakes_dem/lake_", lake, ".tif"))
lake_66 <- raster(paste0("data/buffer_66_percent/lakes_dem/lake_", lake, ".tif"))
lake_100 <- raster(paste0("data/buffer_100_percent/lakes_dem/lake_", lake, ".tif"))

lake_33_bbox <- st_as_sf(st_as_sfc(st_bbox(lake_33)))
lake_66_bbox <- st_as_sf(st_as_sfc(st_bbox(lake_66)))
lake_100_bbox <- st_as_sf(st_as_sfc(st_bbox(lake_100)))

lake_100_bbox_buffer <- st_buffer(lake_100_bbox, 1000)
dem_crop <- crop(dem, extent(lake_100_bbox_buffer))

dem_df <- as.data.frame(dem_crop, xy=TRUE)

lake_surface <- mean(unlist(raster::extract(dem, as(lake_mask_vect, "Spatial"))))

input <- lake_33
input[lake_mask == 1] <- NA
input_df <- as.data.frame(input, xy=TRUE)

observed <- lake_surface - lake_33
observed[lake_mask == 0] <- NA
observed_df <- as.data.frame(observed, xy=TRUE)

#predicted <- raster("") #Load geotiff with predicted values for 33% buffer
predicted <- lake_surface-lake_33+rnorm(length(lake_33[]), sd=2)
predicted[lake_mask == 0] <- NA
predicted_df <- as.data.frame(predicted, xy=TRUE)

predicted_df$difference <- observed_df$lake_22 - predicted_df$lake_22

lake_depth_min <- 0
lake_depth_max <- max(c(predicted_df$lake_22, observed_df$lake_22), na.rm = TRUE)

#Overview and buffer
fig_2_a <- ggplot()+
  geom_raster(data=dem_df, aes(x, y, fill=dtm_10m), show.legend = TRUE)+
  geom_sf(data=lake_mask_vect, fill="dodgerblue", col=NA)+
  geom_sf(data=lake_33_bbox, fill=NA, alpha=0, aes(linetype="33%"), col="black")+
  geom_sf(data=lake_66_bbox, fill=NA, alpha=0, aes(linetype="66%"), col="black")+
  geom_sf(data=lake_100_bbox, fill=NA, alpha=0, aes(linetype="100%"), col="black")+
  scale_linetype_manual(values=c("33%" = 3, "66%" = 2, "100%" = 1), name = "Buffer", guide=guide_legend(override.aes = list(fill = NA)))+
  scale_fill_continuous_sequential(palette="Terrain 2", rev=FALSE, na.value = NA, name="Elevation (m)", limits=c(19, 153))+
  annotation_scale(location="br")+
  scale_x_continuous(expand = c(0,0))+
  scale_y_continuous(expand = c(0,0))+
  theme_void()+
  theme(panel.border = element_rect(colour = "black", fill=NA))

#Model input
fig_2_b <- ggplot()+
  geom_raster(data=input_df, aes(x, y, fill=lake_22), show.legend = FALSE)+
  scale_fill_continuous_sequential(palette="Terrain 2", rev=FALSE, na.value = NA, limits=c(19, 153))+
  geom_sf(data=lake_mask_vect, col="black", fill=NA)+
  scale_x_continuous(expand = c(0,0))+
  scale_y_continuous(expand = c(0,0))+
  theme_void()+
  theme(panel.border = element_rect(colour = "black", fill=NA))

#Ground truth
fig_2_c <- ggplot()+
  geom_raster(data=observed_df, aes(x, y, fill=lake_22), show.legend = TRUE)+
  scale_fill_continuous_sequential(palette="BuPu", rev=FALSE, na.value = NA, 
                                   name="Lake depth (m)", trans="reverse", limits=c(lake_depth_max, 0))+
  geom_sf(data=lake_mask_vect, col="black", fill=NA)+
  scale_x_continuous(expand = c(0,0))+
  scale_y_continuous(expand = c(0,0))+
  theme_void()+
  theme(panel.border = element_rect(colour = "black", fill=NA))

#Predicted
fig_2_d <- ggplot()+
  geom_raster(data=predicted_df, aes(x, y, fill=lake_22), show.legend = TRUE)+
  scale_fill_continuous_sequential(palette="BuPu", rev=FALSE, na.value = NA, 
                                   name="Lake depth (m)", trans="reverse", limits=c(lake_depth_max, 0))+
  geom_sf(data=lake_mask_vect, col="black", fill=NA)+
  scale_x_continuous(expand = c(0,0))+
  scale_y_continuous(expand = c(0,0))+
  theme_void()+
  theme(panel.border = element_rect(colour = "black", fill=NA))

#Difference
fig_2_e <- ggplot()+
  geom_raster(data=predicted_df, aes(x, y, fill=difference), show.legend = TRUE)+
  scale_fill_continuous_diverging(palette="Blue-Red", rev=FALSE, na.value = NA, name="Difference (m)")+
  geom_sf(data=lake_mask_vect, col="black", fill=NA)+
  scale_x_continuous(expand = c(0,0))+
  scale_y_continuous(expand = c(0,0))+
  theme_void()+
  theme(panel.border = element_rect(colour = "black", fill=NA))

figure_2 <- fig_2_a / (fig_2_b + fig_2_c) / (fig_2_d + fig_2_e) + plot_annotation(tag_levels = "a")+plot_layout(guides="collect", heights = c(1, 0.5, 0.5))

figure_2

ggsave("figures/figure_2.png", figure_2, width = 130, height = 200, units = "mm")


# #Supplementary figure to explain pretraining??
# target <- readPNG("data/target.png")
# mask <- readPNG("data/mask.png")
# hat <- readPNG("data/hat.png")
# 
# diff <- target - hat
# diff[mask == 0] = NA
# 
# target_df <- as.data.frame(raster(target), xy=TRUE)
# mask_df <- as.data.frame(raster(mask), xy=TRUE)
# diff_df <- as.data.frame(raster(diff), xy=TRUE)
# 
# fig_target <- ggplot()+
#   geom_raster(data=target_df, aes(x, y, fill=layer), show.legend = FALSE)+
#   theme_void()+
#   scale_fill_continuous_sequential(palette="Terrain 2", rev=FALSE, na.value = NA)+
#   ggtitle("Ground truth")+
#   coord_equal()
# 
# fig_target_masked <- fig_target+
#   geom_raster(data=mask_df, aes(x, y, alpha=factor(layer)), show.legend = FALSE, fill="black")+
#   scale_alpha_manual(values=c(0, 0.5))+
#   ggtitle("Ground truth with mask")+
#   coord_equal()
# 
# fig_diff <- ggplot()+
#   geom_raster(data=diff_df, aes(x, y, fill=layer), show.legend = FALSE)+
#   theme_void()+
#   scale_fill_continuous_diverging(rev=FALSE, na.value = NA, palette="Blue-Red 3")+
#   ggtitle("Ground truth - predicted")+
#   coord_equal()
# 
# figure_2 <- fig_target + fig_target_masked + fig_diff & theme(plot.title = element_text(hjust=0.5))
# 
# ggsave("figures/figure_2.png", figure_2, width = 174, height = 70, units = "mm")
