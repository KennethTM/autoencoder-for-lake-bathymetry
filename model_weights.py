import torch
import os

#Select to save i.e. extract state dict from pytorchlightning checkpoint and save with torch

def main():
    model_dir = "lightning_logs/"

    models = [
            "lake_models/buffer_100_weights_dem_4/checkpoints/epoch=408-step=4907.ckpt",
            "lake_models/buffer_100_weights_dem_8/checkpoints/epoch=327-step=3935.ckpt",
            "lake_models/buffer_100_weights_dem_16/checkpoints/epoch=161-step=1943.ckpt",
            "lake_models/buffer_100_weights_dem_32/checkpoints/epoch=337-step=4055.ckpt",
            "dem_models/dem_4/checkpoints/last.ckpt",
            "dem_models/dem_8/checkpoints/last.ckpt",
            "dem_models/dem_16/checkpoints/last.ckpt",
            "dem_models/dem_32/checkpoints/last.ckpt"
            ]

    dir_out = "model_weights/"

    for i in models:
        path = os.path.join(model_dir, i)
        file_out = i.replace("/", "_").replace("_checkpoints", "").replace(".ckpt", ".pt")
        path_out = os.path.join(dir_out, file_out)

        state_dict = torch.load(path)["state_dict"]

        #Remove "unet." prefix in state dict keys
        new_state_dict = dict(zip([i.replace("unet.", "") for i in state_dict.keys()], state_dict.values()))

        torch.save(new_state_dict, path_out)

if __name__ == "__main__":
    main()