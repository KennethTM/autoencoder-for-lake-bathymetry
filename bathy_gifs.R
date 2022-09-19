source("libs_and_funcs.R")

lakes <- read_csv("data/lakes_summary_partition.csv")

bathy_3d_gif <- function(lake){
  
  buffer_dir <- "data/buffer_100_percent/"
  lake_obs <- raster(paste0(buffer_dir, "lakes_dem/lake_", lake, ".tif"))
  lake_mask <- raster(paste0(buffer_dir, "lakes_mask/lake_", lake, ".tif"))
  
  lake_mask_na <- lake_mask
  lake_mask_na[lake_mask_na == 0] <- NA
  lake_boundary <- boundaries(lake_mask_na, "outer")
  lake_elev <- lakes[lakes$lake_id == lake, ]$elev
  
  lake_obs_mask <- mask(lake_obs, lake_mask, maskvalue=0)
  lake_obs_mask[lake_boundary==1] <- lake_elev
  lake_obs_mask <- trim(lake_obs_mask)
  
  lake_pred <- raster(paste0(buffer_dir, "lakes_pred/lake_", lake, ".tif"))
  lake_pred[lake_pred==0] <- NA
  lake_pred[lake_boundary==1] <- lakes[lakes$lake_id == lake, ]$elev
  lake_pred_mask <- trim(lake_pred)
  
  lake_cubic <- raster(paste0(buffer_dir, "lakes_cubic/lake_", lake, ".tif"))
  lake_cubic[lake_cubic==0] <- NA
  lake_cubic[lake_boundary==1] <- lakes[lakes$lake_id == lake, ]$elev
  lake_cubic_mask <- trim(lake_cubic)
  
  lake_obs_mat <- raster_to_matrix(lake_obs_mask)
  lake_pred_mat <- raster_to_matrix(lake_pred_mask)
  lake_cubic_mat <- raster_to_matrix(lake_cubic_mask)
  
  bathy_3d(lake_obs_mat)
  render_movie(paste0("gifs/", "/", lake, "_obs.gif"), frames=180, title_text = "Ground truth")
  rgl::rgl.close()
  
  bathy_3d(lake_pred_mat)
  render_movie(paste0("gifs/", "/", lake, "_pred.gif"), frames=180, title_text = "Predicted")
  rgl::rgl.close()
  
  bathy_3d(lake_cubic_mat)
  render_movie(paste0("gifs/", "/", lake, "_cubic.gif"), frames=180, title_text = "Cubic interpolation")
  rgl::rgl.close()
  
}


bathy_3d_gif(58) #6
