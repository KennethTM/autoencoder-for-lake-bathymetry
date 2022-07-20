from re import I
import traceback
import pandas as pd
from tensorboard.backend.event_processing.event_accumulator import EventAccumulator
from helpers import buffer_list, weights_list, init_features_list

#Extract logs from tensorboard to data frame
#https://stackoverflow.com/questions/71239557/export-tensorboard-with-pytorch-data-into-csv-with-python
def log2df(path):
    runlog_data = pd.DataFrame({"metric": [], "value": [], "step": []})
    try:
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
    #Dirty catch of DataLossError
    except Exception:
        print("Event file possibly corrupt: {}".format(path))
        traceback.print_exc()
    return runlog_data

#Logs for dem model training
dem_dfs = []

for f in init_features_list:
    path="lightning_logs/dem_models/dem_{}/".format(str(f))
    df=log2df(path)
    df = df.query('metric == "val_loss" | metric == "val_loss_original_scale"')
    df["init_features"] = f
    dem_dfs.append(df)

#Logs for lake model training
grid_list = [(b, w, f) for b in buffer_list for w in weights_list for f in init_features_list]

lake_dfs = []

for b, w, f in grid_list:
    path="lightning_logs/lake_models/buffer_{}_weights_{}_{}/".format(b, w, str(f))
    df=log2df(path)
    df = df.query('metric == "val_loss" | metric == "val_loss_original_scale"')
    df["buffer"] = b
    df["weights"] = w
    df["init_features"] = f
    lake_dfs.append(df)

#Concat df's and write to csv
dem_df = pd.concat(dem_dfs)
dem_df.to_csv("data/dem_model_loss.csv", index=False)

lake_df = pd.concat(lake_dfs)
lake_df.to_csv("data/lake_model_loss.csv", index=False)
