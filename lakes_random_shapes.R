source("libs_and_funcs.R")

#Sample random Danish lake shapes and rasterize to 256 by 256 grid
#Used as masks for unsupervised training of autoencoder
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
