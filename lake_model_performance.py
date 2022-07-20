#SCRIPT DRAFT

from helpers import score_rmse, score_mae, score_corr, dem_scale, dem_inv_scale
import os 
import pickle
import pandas as pd
import numpy as np
from lightning_module import AutoEncoder
import torch

#Evaluate best combination of buffer and Unet model on all observations

result_dict = {"buffer": [], "partition": [], "lake_id": [], "rmse": [], "mae": [], "corr": [], "obs_mean": [], "pred_mean": []}

best_buffer = ''
best_model = AutoEncoder.load_from_checkpoint("lightning_logs/lake_models/checkpoints/XXXX.ckpt")

#Load data
with open(os.path.join("data/buffer_{}_percent".format(best_buffer), "lakes_dict.pickle"), 'rb') as src:
    lakes_dict = pickle.load(src)

#Prediction function for trained unet models, returning either 1d (values=True) or 2d array
def predict_unet(dem, mask, model, values=True):
    
    dem_scale = dem_scale(dem)
    
    target_tensor = torch.from_numpy(dem_scale).unsqueeze(0)
    mask_tensor = torch.from_numpy(mask).unsqueeze(0)

    input_tensor = target_tensor * (1-mask_tensor)
    
    model.eval()

    with torch.no_grad():
        xhat_tensor = model(input_tensor.unsqueeze(0), mask_tensor.unsqueeze(0))
        
    xhat_np = xhat_tensor.squeeze().numpy()
    xhat_np_orig_scale = dem_inv_scale(xhat_np)

    if values:
        return(xhat_np_orig_scale[mask == 1])
    else:
        return(xhat_np_orig_scale)

#Predict for all lakes
for p in ["train", "valid", "test"]:
    
    for i in lakes_dict[p]:
        
        id = i["id"]
        dem = i["lake"]
        mask = i["mask"]
        obs = dem[mask == 1]

        pred = predict_unet(dem, mask, best_model, values=True)

        rmse = score_rmse(obs, pred)
        mae = score_mae(obs, pred)
        corr = score_corr(obs, pred)

        result_dict["buffer"].append(best_buffer)
        result_dict["partition"].append(p)
        result_dict["lake_id"].append(id)
        result_dict["rmse"].append(rmse)
        result_dict["mae"].append(mae)
        result_dict["corr"].append(corr)
        result_dict["obs_mean"].append(np.mean(obs))
        result_dict["pred_mean"].append(np.mean(pred))

df = pd.DataFrame.from_dict(result_dict)
df.to_csv("data/lake_model_performance.csv", index=False)
