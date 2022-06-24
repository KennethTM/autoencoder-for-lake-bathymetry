import cv2
import os
import pickle
import numpy as np 

#Load random lake masks created in "lakes_random_shapes.R" script and save as numpy array

#Load lake masks and convert to array
mask_random_dir = "data/lakes_random/"
mask_random_paths = os.listdir(mask_random_dir)

mask_random_list = []

for i in mask_random_paths:
    lake_path = mask_random_dir+i
    lake_array = cv2.imread(lake_path, cv2.IMREAD_UNCHANGED)
    lake_array_float = lake_array.astype("float32") / 255.0
    mask_random_list.append(lake_array_float)

mask_random_np = np.array(mask_random_list)

#Save file
file_name = "data/lakes_random"

np.savez(file_name, mask = mask_random_np)
