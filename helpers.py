import random
import numpy as np
import cv2
import albumentations as A
from scipy.interpolate import griddata
import pandas as pd
from tensorboard.backend.event_processing.event_accumulator import EventAccumulator
import torch 

#Consts
buffer_list = ['33', '66', '100']
weights_list = ['random', 'dem']
init_features_list = [4, 8, 16, 32]

#Helper functions 

#Scale data range to -1 to 1
def dem_scale(dem, min_val=-25, max_val=175):
    zero_one = (dem - min_val)/(max_val - min_val)
    minus_one = (zero_one*2)-1
    
    return(minus_one)

#Scale range back to original (from -1 to 1)
def dem_inv_scale(dem_scale, min_val=-25, max_val=175):
    zero_one = (dem_scale + 1)/2
    orig_scale = zero_one*(max_val - min_val) + min_val
    
    return(orig_scale)

#Mask augmentation using erotion and dilation
def mask_morph_trans(mask, p=0.5, min_iters = 1, max_iters = 10):
    
    rand = random.uniform(0, 1)
    
    if rand > p:
        return(mask)
        
    kernel = np.ones((3,3),np.uint8)
    morph_op = random.choice([cv2.erode, cv2.dilate])
    iters = random.randint(min_iters, max_iters)
    
    mask_copy = mask.copy()
    mask_morph = morph_op(mask_copy, kernel, iterations=iters)
    
    if mask_morph.sum()/mask.sum() < 0.1:
        return(mask)
    
    return(mask_morph)

#Augmentations
dem_aug = A.Compose([
    A.RandomRotate90(p=0.25),
    A.Flip(p=0.25),
    A.RandomResizedCrop(p=0.25, height=256, width=256, scale=(0.5, 1), interpolation=cv2.INTER_LINEAR)
])

mask_aug = A.Compose([
    A.ShiftScaleRotate(p=0.25, scale_limit=0.2, shift_limit=0.2,
                        interpolation=cv2.INTER_NEAREST, border_mode=cv2.BORDER_CONSTANT),
    A.RandomRotate90(p=0.25),
    A.Flip(p=0.25)
])

lake_aug = A.Compose([
    A.ShiftScaleRotate(p=0.25, border_mode=cv2.BORDER_CONSTANT, interpolation=cv2.INTER_LINEAR),
    A.RandomRotate90(p=0.25),
    A.Flip(p=0.25),
    A.GaussNoise(p=0.25, var_limit=(0, 1e-4)),
    A.GaussianBlur(p=0.25)
])

#Function for computing rmse, mae, and correlation between observed and predicted lake elevations
def score_rmse(obs, pred):
    return(np.sqrt(np.mean(np.square(obs - pred))))

def score_mae(obs, pred):
    return(np.mean(np.abs(obs - pred)))

def score_corr(obs, pred):
    return(np.corrcoef(obs, pred)[1,0])

#Function for computing baseline interpolation of lake bathymetry from surrounding terrain
def baseline(dem, mask, mode):

    if mode == "telea":
        hat = cv2.inpaint(dem, mask.astype("uint8"), 3, cv2.INPAINT_TELEA)
        return(hat[mask == 1])

    elif mode == "ns":
        hat = cv2.inpaint(dem, mask.astype("uint8"), 3, cv2.INPAINT_NS)
        return(hat[mask == 1])

    xy = np.argwhere(mask == 0)
    z = dem[mask == 0]
    xy_hat = np.argwhere(mask == 1)

    if mode == "linear":
        hat = griddata(xy, z, xy_hat, method = "linear")
        return(hat)

    elif mode == "cubic":
        hat = griddata(xy, z, xy_hat, method = "cubic")
        return(hat)

    else:
        return(1)

#Function for converting tensorboard logs to dataframe
def log_to_df(path):
    runlog_data = pd.DataFrame({"metric": [], "value": [], "step": []})
    event_acc = EventAccumulator(path)
    event_acc.Reload()
    tags = event_acc.Tags()["scalars"]
    for tag in tags:
        event_list = event_acc.Scalars(tag)
        values = list(map(lambda x: x.value, event_list))
        step = list(map(lambda x: x.step, event_list))
        r = {"metric": [tag] * len(step), "value": values, "step": step}
        r = pd.DataFrame(r)
        runlog_data = pd.concat([runlog_data, r])

    return runlog_data

#Prediction function for trained unet models, returning either 1d (values=True) or 2d array
def predict_unet(dem, mask, model, values=True):
    
    scaled = dem_scale(dem)
    
    target_tensor = torch.from_numpy(scaled).unsqueeze(0)
    mask_tensor = torch.from_numpy(mask).unsqueeze(0)

    input_tensor = target_tensor * (1-mask_tensor)

    with torch.no_grad():
        xhat_tensor = model(input_tensor.unsqueeze(0), mask_tensor.unsqueeze(0))
        
    xhat_np = xhat_tensor.squeeze().numpy()
    xhat_np_orig_scale = dem_inv_scale(xhat_np)

    if values:
        return(xhat_np_orig_scale[mask == 1])
    else:
        return(xhat_np_orig_scale)
