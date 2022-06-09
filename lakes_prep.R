source("libs_and_funcs.R")

#Cut out lake rasters from dem and assign lake elevations
dem_path <- paste0(data_path, "dtm_10m.tif")
dem <- raster(dem_path)

lake_poly <- st_read(paste0(rawdata_path, "geus_lake_shape/Lake_boundaries_1958-98.shp")) %>% 
  st_zm()

lake_categories <- read_excel(paste0(rawdata_path, "geus_lakes_categories.xlsx"), sheet = "geus_lakes_categories")

lake_categories_sub <- lake_categories |> 
  filter(category %in% c("lake", "stream"))

#remove peat (4), fjord (15) and bornholm (1) lakes in _filter folder
lake_paths_filter <- list.files(paste0(rawdata_path, "geus_lake_raster_filter"), pattern = "*.tif$", full.names = TRUE)
lake_indx <- seq_along(lake_paths_filter)

#for each lake, buffer by sqrt(area) and crop to largest square
for(i in lake_indx){
  
  print(paste0("Lake ", i))
  
  path_i <- lake_paths_filter[i]
  lake <- raster(path_i)
  lake_polymask <- mask(lake, as(st_zm(lake_poly), "Spatial"))
  lake_bbox <- st_bbox(lake_polymask)
  lake_bbox_poly <- st_as_sfc(lake_bbox)
  lake_area <- sum(!is.na(lake_polymask[]))
  buffer_size <- sqrt(lake_area) #adjust this???
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

  lake_resample <- resample(lake_polymask, dem_cut, method = "bilinear")
  lake_mask <- !is.na(lake_resample)
  lake_surface_elev <- mean(dem_cut[lake_mask])
  dem_cut[lake_mask] <- lake_resample[lake_mask]
  lake_mask_surface_elev <- lake_mask * lake_surface_elev

  writeRaster(dem_cut, paste0(data_path, "lakes_dem/lake_", i, ".tif"), options = "COMPRESS=LZW", overwrite = TRUE, NAflag = -9999)
  writeRaster(lake_mask, paste0(data_path, "lakes_mask/lake_", i, ".tif"), options = "COMPRESS=LZW", overwrite = TRUE, NAflag = -9999)
  writeRaster(lake_mask_surface_elev, paste0(data_path, "lakes_surface/lake_", i, ".tif"), options = "COMPRESS=LZW", overwrite = TRUE, NAflag = -9999)
  
}


#sample Danish lakes and rasterize to 256 by 256 grid
dk_lakes <- st_read(paste0(rawdata_path, "DK_StandingWater.gml"))

dk_lakes_sub <- dk_lakes %>% 
  sample_n(1000) %>% 
  st_zm()

for(i in 1:nrow(dk_lakes_sub)){
  lake_sample <- dk_lakes_sub[i, ]
  
  lake_bbox <- st_bbox(lake_sample)
  lake_bbox_poly <- st_as_sfc(lake_bbox)
  lake_bbox_area <- st_area(lake_bbox_poly)
  buffer_size <- sqrt(lake_bbox_area)
  lake_bbox_poly_buf <- st_buffer(lake_bbox_poly, buffer_size)
  
  template_rast <- raster(as(lake_bbox_poly_buf, "Spatial"), nrows = 256, ncols=256)
  lake_rast <- rasterize(as(lake_sample, "Spatial"), template_rast, field=1)
  
  writePNG(as.matrix(lake_rast), paste0(data_path, "lakes_random/sample_", i, ".png"))
  
}
