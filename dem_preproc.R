source("libs_and_funcs.R")

#Create 10m resolution DEM from 1.6 m DEM tiles

#Download Denmark border
dk_border_raw <- getData("GADM", country = "DNK", level = 0, path = rawdata_path)

dk_border <- dk_border_raw %>%
  st_as_sf() %>% 	
  st_crop(xmin = 8, ymin = 54.5, xmax = 14, ymax = 57.8) %>% 	
  st_transform(dk_epsg)	

dk_border_path <- paste0(rawdata_path, "dk_border.sqlite")

st_write(dk_border, dk_border_path, delete_dsn = TRUE)

#Create vrt for hydro dem tiles (1.6 meter resolution)
dem_files <- list.files(paste0(rawdata_path, "DHYM_RAIN"), pattern = "*.ZIP", full.names = TRUE)

dem_asc_files <- sapply(dem_files, function(x){
  zip_files <- unzip(x, list = TRUE)
  asc_file <- zip_files$Name[grepl("*.asc", zip_files$Name)]
  asc_path <- paste0(x, "/", asc_file)
  return(asc_path)
})

dhym <- paste0(getwd(), "/rawdata/dhym_rain.vrt")

gdalbuildvrt(paste0("/vsizip/", dem_asc_files),
             dhym,
             allow_projection_difference = TRUE,
             a_srs = paste0("EPSG:", dk_epsg))

#Create national 10 m dem (terrain model, e.g. without buildings, trees etc.)
#for computing geomorphometrical variables (average function for resampling)
gdalwarp(srcfile = dhym,
         dstfile = paste0(data_path, "dtm_10m.tif"),
         cutline = dk_border_path,
         crop_to_cutline = TRUE,
         overwrite = TRUE,
         dstnodata = -9999,
         r = "average",
         co = c("COMPRESS=LZW", "BIGTIFF=YES"),
         tr = c(10, 10),
         multi = TRUE,
         wm = 8000,
         wo = "NUM_THREADS=ALL_CPUS")

# #cut off bornholm
# gdalwarp(srcfile = paste0(data_path, "dtm_10m.tif"),
#          dstfile = paste0(data_path, "dtm_10m_2.tif"),
#          cutline = dk_border_path,
#          co = "COMPRESS=LZW",
#          crop_to_cutline = TRUE, 
#          overwrite = TRUE)
