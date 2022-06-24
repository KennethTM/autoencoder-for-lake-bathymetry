import torch
from torch.utils.data import Dataset
import random
from helpers import mask_morph_trans, dem_aug, mask_aug, dem_scale

#Classes (train and validation) for loading DEM data for unsupervised training

class DEMTrain(Dataset):

    def __init__(self, array, masks, dem_transform = dem_aug, mask_transform = mask_aug):
      
        self.array = array
        self.masks = masks
        self.n_masks = masks.shape[0]
                
        self.dem_transform = dem_transform
        
        self.mask_transform = mask_transform

    def __getitem__(self, idx):

        target = self.array[idx]
        target_transformed = self.dem_transform(image=target)
        target_trans = target_transformed["image"]
        target_tensor = torch.from_numpy(target_trans).unsqueeze(0)
        
        mask = self.masks[random.choice(range(self.n_masks))]
        mask_transformed = self.mask_transform(image=mask)
        mask_trans = mask_transformed["image"]
        mask_trans_morph = mask_morph_trans(mask_trans, p=0.25)
        mask_tensor = torch.from_numpy(mask_trans_morph).unsqueeze(0)
        
        input_tensor = target_tensor*(1 - mask_tensor)
        
        return input_tensor, target_tensor, mask_tensor

    def __len__(self):
        return self.array.shape[0]

class DEMValid(Dataset):

    def __init__(self, array, masks):
      
        self.array = array
        self.masks = masks

    def __getitem__(self, idx):

        target = self.array[idx]
        target_tensor = torch.from_numpy(target).unsqueeze(0)
        
        mask = self.masks[idx]
        mask_tensor = torch.from_numpy(mask).unsqueeze(0)
        
        input_tensor = target_tensor*(1 - mask_tensor)
        
        return input_tensor, target_tensor, mask_tensor

    def __len__(self):
        return self.array.shape[0]

#Class for loading lake data from dicts

class Lakes(Dataset):

    def __init__(self, lakes_list, transform = None):
      
        self.lakes_list = lakes_list
        self.transform = transform

    def __getitem__(self, idx):
        
        item = self.lakes_list[idx]
        lake = item["lake"]
        mask = item["mask"]
                
        lake = dem_scale(lake)

        if self.transform is not None:
            arrays_trans = self.transform(image = lake, mask = mask)
            lake = arrays_trans["image"]
            mask = arrays_trans["mask"]
            mask = mask_morph_trans(mask)
        
        target_tensor = torch.from_numpy(lake).unsqueeze(0)
        mask_tensor = torch.from_numpy(mask).unsqueeze(0)
        
        input_tensor = target_tensor * (1-mask_tensor)
        
        return input_tensor, target_tensor, mask_tensor

    def __len__(self):
        return len(self.lakes_list)