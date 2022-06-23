#random cutout dem to produce data for autoencoder
import rasterio as rio
import albumentations as A
import os
import cv2
import numpy as np
import random

dem_path = "data/dtm_10m.tif"
cutout_size = 256

#read lake_elev
with rio.open(dem_path) as dem_input:
    dem_profile = dem_input.profile
    dem = dem_input.read(1)

rows, cols = dem.shape

dem[dem == -9999] = np.nan

#crop ratio 64 to 1024 pixels, calc scale
scale_min = 64/rows
scale_max = 1024/rows

#square cutout
cutout_transform = A.OneOf([
    A.RandomResizedCrop(height=cutout_size,width=cutout_size, interpolation= cv2.INTER_NEAREST,
                        scale = (scale_min, scale_max), ratio=(0.75, 1.25)),
    A.RandomResizedCrop(height=cutout_size,width=cutout_size, interpolation= cv2.INTER_LINEAR,
                        scale = (scale_min, scale_max), ratio=(0.75, 1.25)),
    A.RandomResizedCrop(height=cutout_size,width=cutout_size, interpolation= cv2.INTER_CUBIC,
                        scale = (scale_min, scale_max), ratio=(0.75, 1.25)),
    ],
    p=1.0
)

#max count of na cells
max_na_cells = 0.1*(256*256)

#gather 10000 random cutouts
img_cutout = []

i = 0
dataset_size = 10000

while i < dataset_size:
    img_random = cutout_transform(image=dem)
    img_random = img_random["image"]
    
    if np.isnan(img_random).sum() > max_na_cells:
        continue
    
    img_cutout.append(img_random)
    i += 1
    
img_cutout_np = np.stack(img_cutout)
img_cutout_np[np.isnan(img_cutout_np)] = 0

print(np.nanmin(img_cutout_np))
print(np.nanmax(img_cutout_np))

np.savez("data/data.npz", dem = img_cutout_np)
