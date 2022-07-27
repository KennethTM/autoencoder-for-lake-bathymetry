#Figures for manuscript

source("libs_and_funcs.R")

#Table 1
#Lake summary statistics
lakes <- read_csv("data/lakes_summary_partition.csv")

table_1 <- lakes |> 
  mutate(area_ha = area*10^-4) |> #area from m2 to ha
  dplyr::select(area_ha, elev, mean_depth, max_depth) |> 
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

#Figure 1
#Elevation map of Denmark and lakes
dem_coarse <- getData(name = "alt", path = "data/", country="DNK")
dem_course_crop <- trim(crop(dem_coarse, extent(c(8, 14, 54.5, 57.8))))
dem_utm <- projectRaster(dem_course_crop, crs = dk_epsg, method="bilinear")
dem_df <- as.data.frame(dem_utm, xy=TRUE)

dk_iceage <- st_read("data/dk_iceage.sqlite")
dk_border <- st_read("data/dk_border.sqlite")
dk_iceage_cut <- dk_iceage |> 
  st_cast("LINESTRING") |> 
  st_intersection(dk_border) |> 
  st_collection_extract("LINESTRING")

lakes <- read_csv("data/lakes_summary_partition.csv")
lakes_sf <- lakes |> 
  st_as_sf(crs=dk_epsg, coords=c("x", "y"))

figure_1 <- ggplot()+
  geom_raster(data=dem_df, aes(x, y, fill=DNK_msk_alt))+
  scale_fill_continuous_sequential(palette="Terrain 2", rev=FALSE, na.value = NA, name="Elevation (m)")+
  geom_sf(data = dk_iceage_cut, linetype=2, col = "black", show.legend = FALSE)+
  geom_sf(data=lakes_sf, col="black", shape=1)+
  xlab("Longitude")+
  ylab("Latitude")+
  theme(legend.position = "bottom")+
  guides(fill = guide_colorbar(ticks = FALSE, title.position = "top", title.hjust = 0.5, barwidth = unit(60, "mm")))

figure_1

ggsave("figures/figure_1.png", figure_1, width = 84, height = 110, units = "mm")

#Figure 2
#Overview of cropping approach and an example observed/predicted lake bathymetry
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

#Figure 3
#Performance of baseline and unets models
baseline <- read_csv("data/baseline_performance.csv")

baseline_models <- baseline |> 
  group_by(buffer, mode) |> 
  summarise(all = mean(mae), valid = mean(mae[partition == "valid"])) |> 
  gather(partition, mae, valid, all) |> 
  mutate(model_label = case_when(mode == "ns" ~ "Navier-Stokes",
                                 mode == "telea" ~ "Telea",
                                 mode == "linear" ~ "Linear",
                                 mode == "cubic" ~ "Cubic"),
         model = paste0("Baseline[", model_label,"]"))

#Unet models
lake_loss <- read_csv("data/lake_model_loss.csv")

lake_loss_original <- lake_loss |> 
  group_by(metric, buffer, weights, init_features) |> 
  mutate(epoch = 1:n(),
         complexity = case_when(init_features == 4 ~ "0.121",
                                init_features == 8 ~ "0.485",
                                init_features == 16 ~ "1.9",
                                init_features == 32 ~ "7.8")) |> 
  ungroup() |> 
  filter(metric == "val_loss_original_scale")

lake_best_models <- lake_loss_original |> 
  group_by(buffer, weights, init_features) |> 
  summarise(best_epoc = epoch[which.min(value)], partition = "valid", mae = min(value)) |> 
  ungroup() |> 
  mutate(weights_label = ifelse(weights == "dem", "DEM", "Random"),
         model = paste0("'U-net'['", init_features, "-", weights_label,"']"))

fig_data <- bind_rows(lake_best_models, baseline_models) |>
  mutate(model = factor(model),
         buffer_label = factor(paste0(buffer, "%"), levels = c("33%", "66%", "100%")),
         Data = ifelse(partition == "all", "All", "Validation")) 

figure_3 <- fig_data |> 
  ggplot(aes(reorder(model, -mae), mae, fill=Data))+
  geom_col(position = position_dodge(), col="black")+
  scale_x_discrete(labels = function(l) parse(text=l))+
  facet_grid(.~buffer_label)+
  coord_flip()+
  ylab("Mean absolute error (m)")+
  xlab("Model")+
  scale_fill_manual(values = c("All" = "grey", "Validation" = "white"))+
  theme(strip.background = element_blank(), axis.text.y = element_text(hjust=0))

figure_3

ggsave("figures/figure_3.png", figure_3, width = 174, height = 100, units = "mm")


#Figure 4
#Histograms with performance metrics for best model and obs vs pred avg elevation (2x2 plot) for all lakes and test set only

#Figure 5
#Example of prediction with ground truth, best baseline and best deep learning model

# library(rayshader)
# 
# lake <- 22 #Borre Sø
# lake_33 <- raster(paste0("data/buffer_33_percent/lakes_dem/lake_", lake, ".tif"))
# lake_mask <- raster(paste0("data/buffer_33_percent/lakes_mask/lake_", lake, ".tif"))
# 
# lake_33_mask <- mask(lake_33, lake_mask, maskvalue=0)
# lake_33_mask <- trim(lake_33_mask)
# 
# lake_mat <- raster_to_matrix(lake_33)
# 
# ray <- ray_shade(lake_mat, zscale=10)
# amb <- ambient_shade(lake_mat, zscale=10)
# 
# lake_mat %>%
#   sphere_shade(zscale=10, texture = "imhof1") %>%
#   add_shadow(ray, 0.5) %>%
#   add_shadow(amb, 0) %>%
#   plot_3d(lake_mat, solid = TRUE, shadow = TRUE, water = TRUE, waterdepth = 20, zscale=10)


#Supplementary material
#Figure S1
#Validation loss during training of DEM models
dem_loss <- read_csv("data/dem_model_loss.csv")

dem_loss_original <- dem_loss |> 
  group_by(metric, init_features) |> 
  mutate(epoch = 1:n(),
         Model = factor(paste0("'U-net'[", init_features,"]"))) |> 
  ungroup() |> 
  filter(metric == "val_loss_original_scale")
  
fig_s1 <- dem_loss_original |> 
  ggplot(aes(epoch, value, col=Model))+
  geom_line()+
  scale_color_viridis_d(direction = -1, labels = function(l) parse(text=l))+
  ylab("Mean absolute error (m)")+
  xlab("Epoch")+
  theme(legend.position = c(0.8, 0.8))+
  coord_cartesian(ylim=c(2, 10))+
  theme(legend.text.align = 0)

fig_s1

ggsave("figures/figure_s1.png", fig_s1, width = 129, height = 100, units = "mm")

#Figure S2
#Validation loss during training of LAKE models
fig_s2 <- lake_loss_original |>
  mutate(buffer_label = factor(paste0(buffer, "%"), levels = c("33%", "66%", "100%")),
         weights_label = factor(ifelse(weights == "dem", "DEM", "Random"), levels=c("Random", "DEM")),
         value = ifelse(value > 15, NA, value),
         Model = factor(paste0("'U-net'[", init_features,"]"), levels=c("'U-net'[4]", "'U-net'[8]", "'U-net'[16]", "'U-net'[32]"))) |> 
  na.omit() |> 
  ggplot(aes(epoch, value, col=Model))+
  geom_line()+
  scale_color_viridis_d(direction = -1, labels = function(l) parse(text=l))+
  ylab("Mean absolute error (m)")+
  xlab("Epoch")+
  geom_hline(yintercept = min(lake_best_models$mae), linetype=2)+
  facet_grid(weights_label~buffer_label, scales="free_y")+
  theme(strip.background = element_blank(), legend.text.align = 0)

fig_s2

ggsave("figures/figure_s2.png", fig_s2, width = 174, height = 120, units = "mm")
