library(raster);library(sf);library(tidyverse);library(png);library(readxl);
library(patchwork);library(colorspace);library(ggspatial);library(RColorBrewer);
library(rayshader);library(png);library(grid);library(magick);library(RcppCNPy);
library(reshape2)
#;library(gdalUtils)

set.seed(9999)

rawdata_path <- paste0(getwd(), "/rawdata/")
data_path <- paste0(getwd(), "/data/")

lake_paths <- list.files(path = paste0(rawdata_path, "geus_lake_raster"), pattern = "*.tif$", full.names = TRUE)
lake_paths <- lake_paths[!grepl("_25m.tif", lake_paths)]

dk_epsg <- 25832

#Aq. Sci.:For most journals the figures should be 39 mm, 84 mm, 129 mm, or 174 mm wide and not higher than 234 mm.
theme_pub <- theme_bw() + 
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        axis.text = element_text(colour = "black"), 
        strip.background = element_rect(fill = "white"))
theme_set(theme_pub)

#3D plot of lake bathymetry maps
bathy_3d <- function(matrix, theta = 200){
  col_low <- brewer.pal(5, "Blues")[5]
  col_high <- brewer.pal(8, "Blues")[2]
  bu_pn_pal <- colorRampPalette(c(col_low, col_high))
  
  ray <- ray_shade(matrix, zscale=1, lambert = FALSE)
  amb <- ambient_shade(matrix, zscale=1)
  
  matrix %>%
    height_shade(texture = bu_pn_pal(256)) %>%
    add_shadow(ray, 0.5) %>%
    add_shadow(amb, 0.2)  %>%
    plot_3d(matrix, zscale = 1, fov = 0, theta = theta, phi = 25, shadow=FALSE,
            windowsize = c(1000, 800), zoom = 0.6, solid = FALSE)
}

bathy_3d_compare <- function(lake, subfolder){
  
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
  
  theta <- ifelse(lake %in% c(78, 45), 245, 200) #adjust rotation of particular lakes
  
  bathy_3d(lake_obs_mat, theta = theta)
  render_snapshot(paste0("figures/", subfolder, "/fig_", lake, "_obs.png"), clear = TRUE)
  
  bathy_3d(lake_pred_mat, theta = theta)
  render_snapshot(paste0("figures/", subfolder, "/fig_", lake, "_pred.png"), clear = TRUE)
  
  bathy_3d(lake_cubic_mat, theta = theta)
  render_snapshot(paste0("figures/", subfolder, "/fig_", lake, "_cubic.png"), clear = TRUE)
  
}

#Create row of images which can be assembled to a figure
image_row <- function(lake, subfolder){
  obs_path <- paste0("figures/", subfolder, "/fig_", lake, "_obs.png")
  pred_path <- paste0("figures/", subfolder, "/fig_", lake, "_pred.png")
  cubic_path <- paste0("figures/", subfolder, "/fig_", lake, "_cubic.png")
  
  obs_img <- image_read(obs_path)
  pred_img <- image_read(pred_path)
  cubic_img <- image_read(cubic_path)
  
  obs_grob <- rasterGrob(image_trim(obs_img))
  pred_grob <- rasterGrob(image_trim(pred_img))
  cubic_grob <- rasterGrob(image_trim(cubic_img))
  
  row <- lapply(list(obs_grob, pred_grob, cubic_grob), wrap_elements)
  
  return(row)
}

#Function to create standalone legend for figure 5
figure_5_legend <- function(){
  col_low <- brewer.pal(5, "Blues")[5]
  col_high <- brewer.pal(8, "Blues")[2]
  bu_pn_pal <- colorRampPalette(c(col_low, col_high))
  
  z <- matrix(1:100,nrow=1)
  x <- 1
  y <- 1:100 
  image(x,y,z,col=bu_pn_pal(100), axes=FALSE, xlab="", ylab="", font.main = 1, main="Relative depth")
  axis(2, c(1, 100), labels=c("Deep", "Shallow"), las=1)
}
