library(raster);library(sf);library(tidyverse);library(png);library(readxl);
library(patchwork);library(colorspace);library(ggspatial);library(RColorBrewer);
library(rayshader);library(png);library(grid);library(magick)
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
bathy_3d <- function(matrix){
  col_low <- brewer.pal(5, "Blues")[5]
  col_high <- brewer.pal(8, "Blues")[2]
  bu_pn_pal <- colorRampPalette(c(col_low, col_high))
  
  ray <- ray_shade(matrix, zscale=1, lambert = FALSE)
  amb <- ambient_shade(matrix, zscale=1)
  
  matrix %>%
    height_shade(texture = bu_pn_pal(256)) %>%
    add_shadow(ray, 0.5) %>%
    add_shadow(amb, 0.2)  %>%
    plot_3d(matrix, zscale = 1, fov = 0, theta = 200, phi = 30, shadow=FALSE,
            windowsize = c(1000, 800), zoom = 0.75, solid = FALSE)
}

#Create row of images which can be assembled to a figure
image_row <- function(lake){
  obs_path <- paste0("figures/figure_5/fig_", lake, "_obs.png")
  pred_path <- paste0("figures/figure_5/fig_", lake, "_pred.png")
  cubic_path <- paste0("figures/figure_5/fig_", lake, "_cubic.png")
  
  obs_img <- image_read(obs_path)
  pred_img <- image_read(pred_path)
  cubic_img <- image_read(cubic_path)
  
  obs_grob <- rasterGrob(image_trim(obs_img))
  pred_grob <- rasterGrob(image_trim(pred_img))
  cubic_grob <- rasterGrob(image_trim(cubic_img))
  
  row <- lapply(list(obs_grob, pred_grob, cubic_grob), wrap_elements)
  
  return(row)
}
