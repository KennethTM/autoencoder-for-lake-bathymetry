import pandas as pd
import pickle
import numpy as np

#Compute lake summary statistics

with open('data/buffer_33_percent/lakes_dict.pickle', 'rb') as src:
    lakes_dict = pickle.load(src)

result_list = []

splits = ["train", "valid", "test"]

for s in splits:

    lakes = lakes_dict[s]

    for i in lakes:

        ids = i["id"]
        area = i["mask"].sum()*10*10
        elev = i["surface"].max()
        bathy = elev - i["lake"][i["mask"] == 1]
        mean_depth = bathy.mean()
        min_depth = bathy.min()
        max_depth = bathy.max()

        rows, cols = i["lake"].shape
        x_coord = i["profile"]["transform"][2] + (cols//2) * 10
        y_coord = i["profile"]["transform"][5] + (rows//2) * 10

        result_list.append(
            {"ids": ids, "set": s, "x_coord": x_coord, "y_coord":  y_coord,
             "area": area, "max_depth": max_depth, "mean_depth": mean_depth, 
             "elev": elev, "min_depth": min_depth}
        )

result_df = pd.DataFrame.from_dict(result_list)
result_df.sort_values("ids")

result_df.to_csv("data/XXX.csv")