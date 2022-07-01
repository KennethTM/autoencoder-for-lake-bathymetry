import os
import rasterio as rio
import pickle
import random
import pandas as pd

random.seed(9999)

#Include lakes with area > 10 ha, eg. 100000 m2/(10*10 m resolution)
lake_size_thresh = 100000

#Read lake summary
summary = pd.read_csv("data/lakes_summary.csv")
summary_sub = summary[summary["area"] > lake_size_thresh]

#Create column for partioning of lakes
#Split into train/val/test sets of 60/20/20 %
train_len = int(summary_sub.shape[0]*0.6) + 1
valid_len = int(summary_sub.shape[0]*0.2)
test_len = int(summary_sub.shape[0]*0.2) 

print(train_len+valid_len+test_len)

#Shuffle
summary_sub = summary_sub.sample(frac=1)

#Add column with dataset partition
summary_sub["partition"] = "train"
summary_sub["partition"][train_len:(train_len+valid_len)] = "valid"
summary_sub["partition"][(train_len+valid_len):(train_len+valid_len+test_len)] = "test"

#Prepare lakes for modeling and write as dictionaries
buffer_dir = "data/buffer_{}_percent"
lakes_dir = "lakes_dem"
mask_dir = "lakes_mask"
surface_dir = "lakes_surface"

buffer_sizes = [int(i*100) for i in [3/3, 2/3, 1/3]]

lake_id_list = summary_sub["lake_id"].tolist()

for b in buffer_sizes:
  
  lake_list = []

  buffer_dir_b = buffer_dir.format(b)
    
  dataset_dict = {"train": [], "valid": [], "test": []}

  for i, p, e in zip(summary_sub["lake_id"], summary_sub["partition"], summary_sub["elev"]):
  
    lake_path = os.path.join(buffer_dir_b, lakes_dir, "lake_{}.tif".format(i))
    mask_path = os.path.join(buffer_dir_b, mask_dir, "lake_{}.tif".format(i))
    
    with rio.open(lake_path) as src:
        profile = src.profile
        lake = src.read(1)
        
    with rio.open(mask_path) as src:
        mask = src.read(1)
    
    lake[lake == -9999] = 0
    
    lake_dict = {"id": i, "lake": lake, "mask": mask, 
                "surface": e, "profile": profile}

    dataset_dict[p].append(lake_dict)

  #Save object
  dict_file_name = "lakes_dict.pickle"
  with open(os.path.join(buffer_dir_b, dict_file_name), 'wb') as dest:
      pickle.dump(dataset_dict, dest)

#Write new lakes summary table
summary_sub.to_csv("data/lakes_summary_partition.csv")
