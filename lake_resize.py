import os
import rasterio as rio
import cv2
import pickle
import random

random.seed(9999)

lakes_dir = "data/lakes_dem/"
mask_dir = "data/lakes_mask/"
surface_dir = "data/lakes_surface/"

lakes_imgs = os.listdir(lakes_dir)

lake_size_thresh = 100000/(10*10)

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
    
    #lake_resize = cv2.resize(lake, target_size, interpolation = cv2.INTER_LINEAR)
    #mask_resize = cv2.resize(mask, target_size, interpolation = cv2.INTER_NEAREST)
    #surface_resize = cv2.resize(surface, target_size, interpolation = cv2.INTER_NEAREST)
    
    #lake_dict = {"id": i.split(".")[0], "lake": lake_resize, "mask": mask_resize, 
    #             "surface": surface_resize, "profile": profile}
    
    lake_dict = {"id": i.split(".")[0], "lake": lake, "mask": mask, 
                 "surface": surface, "profile": profile}

    if mask.sum() > lake_size_thresh: #include lakes with area > 10 ha, eg. 10000 m2/(10*10 m resolution)
        resize_list.append(lake_dict)

print(len(resize_list))

#split into train/val/test of 60/20/20 %

train_len = int(len(resize_list)*0.6) + 1
valid_len = int(len(resize_list)*0.2)
test_len = int(len(resize_list)*0.2) 

print(train_len+valid_len+test_len)

random.shuffle(resize_list)

train_list = resize_list[:train_len]
valid_list = resize_list[train_len:(train_len+valid_len)]
test_list = resize_list[(train_len+valid_len):(train_len+valid_len+test_len)]

print(len(train_list)+len(valid_list)+len(test_list))

dataset_dict = {"train": train_list, "valid": valid_list, "test": test_list}

#save object
with open('data/lakes_datasets.pickle', 'wb') as dst:
    pickle.dump(dataset_dict, dst)
