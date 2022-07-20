from helpers import baseline, buffer_list, score_rmse, score_mae, score_corr
import os 
import pickle
import pandas as pd

result_dict = {"buffer": [], "partition": [], "lake_id": [], "mode": [], "rmse": [], "mae": [], "corr": []}

#Evaluate baseline performance on all lakes
for b in buffer_list:

    with open(os.path.join("data/buffer_{}_percent".format(b), "lakes_dict.pickle"), 'rb') as src:
        lakes_dict = pickle.load(src)

    for p in ["train", "valid", "test"]:
        
        for i in lakes_dict[p]:
            
            id = i["id"]
            dem = i["lake"]
            mask = i["mask"]
            obs = dem[mask == 1]

            for m in ["telea", "ns", "linear", "cubic"]:

                pred = baseline(dem, mask, mode = m)
                rmse = score_rmse(obs, pred)
                mae = score_mae(obs, pred)
                corr = score_corr(obs, pred)

                result_dict["buffer"].append(b)
                result_dict["partition"].append(p)
                result_dict["lake_id"].append(id)
                result_dict["mode"].append(m)
                result_dict["rmse"].append(rmse)
                result_dict["mae"].append(mae)
                result_dict["corr"].append(corr)

df = pd.DataFrame.from_dict(result_dict)
df.to_csv("data/baseline_performance.csv", index=False)
