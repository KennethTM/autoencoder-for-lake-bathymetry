import numpy as np
import random
import torch
import pytorch_lightning as pl
from lightning_module import AutoEncoder
from helpers import dem_scale, dem_inv_scale
from data_classes import DEMTrain

pl.seed_everything(9999)
random.seed(9999)

#Create examples data used for dem_model for figure s1
def main():
    figure_s1_path = "figures/figure_s1"

    data = np.load("data/data.npz")
    dem_data = dem_scale(data["dem"])

    train = dem_data[:8000]
    valid = dem_data[8000:]

    random_mask = np.load("data/lakes_random.npz")
    mask_data = random_mask["mask"].astype("float32")

    train_dataset = DEMTrain(train, mask_data)

    weights_path = "lightning_logs/dem_models/dem_32/checkpoints/last.ckpt"
    dem_model = AutoEncoder().load_from_checkpoint(weights_path)
    dem_model.eval()

    for i in range(3):
        input_tensor, target_tensor, mask_tensor = train_dataset[i]

        with torch.no_grad():
            xhat_tensor = dem_model(input_tensor.unsqueeze(0), mask_tensor.unsqueeze(0))
            
        xhat_np = xhat_tensor.squeeze().numpy()
        xhat_np_orig_scale = dem_inv_scale(xhat_np)

        target_np = dem_inv_scale(target_tensor.squeeze().numpy())
        mask_np = mask_tensor.squeeze().numpy()

        np.save(figure_s1_path+"/target_{}.npy".format(i), target_np.astype("double"))
        np.save(figure_s1_path+"/mask_{}.npy".format(i), mask_np.astype("double"))
        np.save(figure_s1_path+"/predicted_{}.npy".format(i), xhat_np_orig_scale.astype("double"))

if __name__ == "__main__":

    main()