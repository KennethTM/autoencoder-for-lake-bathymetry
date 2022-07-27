from helpers import buffer_list, weights_list, init_features_list, log_to_df
import pandas as pd

#Extract tensorboard logs and save as .csv

def main():
    
    #Logs for dem model training
    dem_dfs = []

    for f in init_features_list:
        path="lightning_logs/dem_models/dem_{}/".format(str(f))
        df=log_to_df(path)
        df = df.query('metric == "val_loss" | metric == "val_loss_original_scale"')
        df["init_features"] = f
        dem_dfs.append(df)

    #Logs for lake model training
    grid_list = [(b, w, f) for b in buffer_list for w in weights_list for f in init_features_list]

    lake_dfs = []

    for b, w, f in grid_list:
        path="lightning_logs/lake_models/buffer_{}_weights_{}_{}/".format(b, w, str(f))
        df=log_to_df(path)
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

if __name__ == "__main__":
    main()