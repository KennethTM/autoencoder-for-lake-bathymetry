import os
import rasterio as rio
import cv2
import pickle

lakes_dir = "data/lakes_dem/"
mask_dir = "data/lakes_mask/"
surface_dir = "data/lakes_surface/"

lakes_imgs = os.listdir(lakes_dir)

target_size = (256, 256)

resize_list = []

for i in lakes_imgs:
    lake_path = lakes_dir+i
    mask_path = mask_dir+i
    surface_path = surface_dir+i
    
    with rio.open(lake_path) as src:
        profile = src.profile
        lake = src.read(1)
        
    with rio.open(mask_path) as src:
        mask = src.read(1)
        
    with rio.open(surface_path) as src:
        surface = src.read(1)
    
    lake[lake == -9999] = 0
    lake_resize = cv2.resize(lake, target_size, interpolation = cv2.INTER_LINEAR)
    mask_resize = cv2.resize(mask, target_size, interpolation = cv2.INTER_NEAREST)
    surface_resize = cv2.resize(surface, target_size, interpolation = cv2.INTER_NEAREST)
    
    lake_dict = {"id": i.split(".")[0], "lake": lake_resize, "mask": mask_resize, 
                 "surface": surface_resize, "profile": profile}

    resize_list.append(lake_dict)

#save object
with open('data/lakes.pickle', 'wb') as dst:
    pickle.dump(resize_list, dst)

