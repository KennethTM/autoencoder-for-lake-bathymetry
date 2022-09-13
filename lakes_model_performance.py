from helpers import score_rmse, score_mae, score_corr, predict_unet
import os 
import pickle
import pandas as pd
import numpy as np
from lightning_module import AutoEncoder
import rasterio as rio

#Evaluate best combination of buffer and Unet model on all observations
def main():
    result_dict = {"buffer": [], "partition": [], "lake_id": [], "rmse": [], "mae": [], "corr": [], "obs_mean": [], "pred_mean": [], "pred_zmean": [], "pred_zmax": []}

    best_buffer = '100'
    best_buffer_dir = "data/buffer_{}_percent".format(best_buffer)

    best_model_path = "lightning_logs/lake_models/buffer_{}_weights_dem_32/checkpoints/epoch=337-step=4055.ckpt".format(best_buffer)
    best_model = AutoEncoder.load_from_checkpoint(best_model_path)
    best_model.eval()

    #Load data
    with open(os.path.join(best_buffer_dir, "lakes_dict.pickle"), 'rb') as src:
        lakes_dict = pickle.load(src)

    #Predict for all lakes
    for p in ["train", "valid", "test"]:
        
        for i in lakes_dict[p]:
            
            id = i["id"]
            dem = i["lake"]
            mask = i["mask"]
            elev = i["surface"]
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
            result_dict["pred_zmean"].append(np.mean(elev-pred))
            result_dict["pred_zmax"].append(np.max(elev-pred))

            #Write predicted lake bathymetry to file
            pred_grid = predict_unet(dem, mask, best_model, values=False)
            pred_grid_mask = pred_grid*mask
            profile = i["profile"]
            pred_path = os.path.join(best_buffer_dir, "lakes_pred", "lake_{}.tif".format(id))

            with rio.open(pred_path, 'w', **profile) as dst:
                dst.write(pred_grid_mask, 1)

    #Write performance metric to file
    df = pd.DataFrame.from_dict(result_dict)
    df.to_csv("data/lake_model_performance.csv", index=False)

if __name__ == "__main__":
    main()