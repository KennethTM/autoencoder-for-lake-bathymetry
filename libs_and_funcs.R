library(raster);library(sf);library(tidyverse);library(png);library(readxl);
library(patchwork);library(colorspace);library(ggspatial)
#;library(fasterize)
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

