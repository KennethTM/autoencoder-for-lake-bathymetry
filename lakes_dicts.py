import os
import rasterio as rio
import pickle
import random

random.seed(9999)

#Prepare lakes for modeling and write as dictionaries
buffer_dir = "data/buffer_{}_percent"
lakes_dir = "lakes_dem"
mask_dir = "lakes_mask"
surface_dir = "lakes_surface"

#Include lakes with area >´10 ha, eg. 100000 m2/(10*10 m resolution)
lake_size_thresh = 100000/(10*10)

buffer_sizes = [int(i*100) for i in [3/3, 2/3, 1/3]]

for b in buffer_sizes:
  
  lake_list = []

  buffer_dir_b = buffer_dir.format(b)
  
  lakes_imgs = os.listdir(os.path.join(buffer_dir_b, lakes_dir))
  
  for i in lakes_imgs:
  
      lake_path = os.path.join(buffer_dir_b, lakes_dir, i)
      mask_path = os.path.join(buffer_dir_b, mask_dir, i)
      surface_path = os.path.join(buffer_dir_b, surface_dir, i)
      
      with rio.open(lake_path) as src:
          profile = src.profile
          lake = src.read(1)
          
      with rio.open(mask_path) as src:
          mask = src.read(1)
          
      with rio.open(surface_path) as src:
          surface = src.read(1)
      
      lake[lake == -9999] = 0
      
      lake_dict = {"id": i.split(".")[0], "lake": lake, "mask": mask, 
                   "surface": surface, "profile": profile}
  
      if mask.sum() > lake_size_thresh: 
          lake_list.append(lake_dict)
    
  #Split into train/val/test sets of 60/20/20 %
  train_len = int(len(lake_list)*0.6) + 1
  valid_len = int(len(lake_list)*0.2)
  test_len = int(len(lake_list)*0.2) 
  
  print(train_len+valid_len+test_len)
  
  random.shuffle(lake_list)
  
  train_list = lake_list[:train_len]
  valid_list = lake_list[train_len:(train_len+valid_len)]
  test_list = lake_list[(train_len+valid_len):(train_len+valid_len+test_len)]
  
  print(len(train_list)+len(valid_list)+len(test_list))
  
  dataset_dict = {"train": train_list, "valid": valid_list, "test": test_list}
  
  #save object
  dict_file_name = "lakes_dict.pickle"
  with open(os.path.join(buffer_dir_b, dict_file_name), 'wb') as dest:
      pickle.dump(dataset_dict, dest)
