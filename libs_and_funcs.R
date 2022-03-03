library(raster);library(sf);library(tidyverse);library(gdalUtils);library(png)

rawdata_path <- paste0(getwd(), "/rawdata/")
data_path <- paste0(getwd(), "/data/")

lake_paths <- list.files(path = paste0(rawdata_path, "geus_lake_raster"), pattern = "*.tif$", full.names = TRUE)
lake_paths <- lake_paths[!grepl("_25m.tif", lake_paths)]

dk_epsg <- 25832
