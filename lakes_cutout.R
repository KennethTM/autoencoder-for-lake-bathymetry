source("libs_and_funcs.R")

#Cut out lake rasters from dem and assign lake elevations
dem_path <- paste0(data_path, "dtm_10m.tif")
dem <- raster(dem_path)

lake_poly <- st_read(paste0(rawdata_path, "geus_lake_shape/Lake_boundaries_1958-98.shp")) %>% 
  st_zm()

lake_categories <- read_excel(paste0(rawdata_path, "geus_lakes_categories.xlsx"), sheet = "geus_lakes_categories")

lake_categories_sub <- lake_categories |> 
  filter(category %in% c("lake", "stream"))

#Filter lakes
#Remove peat lakes (4), fjord/beach lakes (16) and Bornholm (1, outside study area) in "_filter" folder
lake_paths_filter <- list.files(paste0(rawdata_path, "geus_lake_raster_filter"), pattern = "*.tif$", full.names = TRUE)
lake_indx <- seq_along(lake_paths_filter)

buffer_sizes <- c(3/3, 2/3, 1/3)

result_list <- vector("list", length = length(lake_indx))

#For each buffer size prepare lakes
for(b in buffer_sizes){
  buffer_folder <- paste0(data_path, paste0("buffer_", as.integer(b*100), "_percent", "/"))
  
  #For each lake, buffer by sqrt(area) and crop to largest square
  for(i in lake_indx){
    
    print(paste0("Lake ", i))
    
    path_i <- lake_paths_filter[i]
    lake <- raster(path_i)
    lake_polymask <- mask(lake, as(st_zm(lake_poly), "Spatial"))
    lake_bbox <- st_bbox(lake_polymask)
    lake_bbox_poly <- st_as_sfc(lake_bbox)
    lake_area <- sum(!is.na(lake_polymask[]))
    buffer_size <- sqrt(lake_area) * b 
    lake_bbox_poly_buf <- st_buffer(lake_bbox_poly, buffer_size)
    
    cut_bbox <- st_bbox(lake_bbox_poly_buf)
    cut_bbox_width <- cut_bbox["xmax"] - cut_bbox["xmin"]
    cut_bbox_height <- cut_bbox["ymax"] - cut_bbox["ymin"]
    padding <- abs(cut_bbox_width-cut_bbox_height)/2
    
    if(cut_bbox_width > cut_bbox_height){
      cut_bbox["ymax"] <- cut_bbox["ymax"] + padding
      cut_bbox["ymin"] <- cut_bbox["ymin"] - padding
    }else{
      cut_bbox["xmax"] <- cut_bbox["xmax"] + padding
      cut_bbox["xmin"] <- cut_bbox["xmin"] - padding
    }
    
    cut_extent <- extent(cut_bbox["xmin"], cut_bbox["xmax"], cut_bbox["ymin"], cut_bbox["ymax"])
    cut_align <- alignExtent(cut_extent, dem)
    
    dem_cut <- crop(dem, cut_align)
    
    if(nrow(dem_cut) != ncol(dem_cut)){
      if(nrow(dem_cut) > ncol(dem_cut)){
        cut_align@xmax <- cut_align@xmax + 10
      }else{
        cut_align@ymax <- cut_align@ymax + 10
      }
    }
    
    dem_cut <- crop(dem, cut_align)
    
    mult_factor <- nrow(dem_cut) %% 2^4
    if(mult_factor != 0){
      dem_cut_bbox <- extent(dem_cut)
      mult_factor_pad <- (2^4 - mult_factor)*10
      dem_cut_bbox@xmax <- dem_cut_bbox@xmax + mult_factor_pad
      dem_cut_bbox@ymax <- dem_cut_bbox@ymax + mult_factor_pad
      dem_cut <- crop(dem, dem_cut_bbox)
    }
    
    lake_resample <- resample(lake_polymask, raster(dem_cut), method = "bilinear")
    lake_mask <- !is.na(lake_resample)
    lake_surface_elev <- mean(dem_cut[lake_mask], na.rm=TRUE) #lake surface elevation extracted from dem
    dem_cut[lake_mask] <- lake_resample[lake_mask]

    #Write summary statistics for each lake
    if(b == 1){
      lake_dephts <- lake_surface_elev - na.omit(lake_resample[])
      lake_coords <- st_coordinates(st_centroid(lake_bbox_poly))
      
      result_list[[i]] <- data.frame(lake_id = i, area = lake_area, elev = lake_surface_elev,
                                     min_depth = min(lake_dephts), max_depth = max(lake_dephts),
                                     mean_depth = mean(lake_dephts), x = lake_coords[1], y = lake_coords[2])
    }
    
    writeRaster(dem_cut, paste0(buffer_folder, "lakes_dem/lake_", i, ".tif"), options = "COMPRESS=LZW", overwrite = TRUE, NAflag = -9999)
    writeRaster(lake_mask, paste0(buffer_folder, "lakes_mask/lake_", i, ".tif"), options = "COMPRESS=LZW", overwrite = TRUE, NAflag = -9999)
    
  }
}

#Combine lake summaries and write to file
result_df <- bind_rows(result_list)
write_csv(result_df, "data/lakes_summary.csv")
