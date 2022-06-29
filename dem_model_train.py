import numpy as np
import random
from torch.utils.data import DataLoader
import pytorch_lightning as pl
from pytorch_lightning.callbacks import ModelCheckpoint
from lightning_module import AutoEncoder
from helpers import dem_scale
from data_classes import DEMTrain, DEMValid

pl.seed_everything(9999)
random.seed(9999)

#Define main function
def dem_training():

    #Load DEM data
    data = np.load("data/data.npz")
    dem_data = dem_scale(data["dem"])

    train = dem_data[:8000]
    valid = dem_data[8000:]

    #Load mask data
    random_mask = np.load("data/lakes_random.npz")
    mask_data = random_mask["mask"]

    random_mask_idx = random.choices(range(mask_data.shape[0]), k=valid.shape[0])
    valid_mask = mask_data[random_mask_idx]

    #Create datasets
    train_dataset = DEMTrain(train, mask_data)
    valid_dataset = DEMValid(valid, valid_mask)

    #Create dataloaders
    train_loader = DataLoader(train_dataset, batch_size=32, num_workers=0, shuffle = True)
    val_loader = DataLoader(valid_dataset, batch_size=32, num_workers=0, shuffle = False)

    #Initiate models of differing complexity
    dem_model_8 = AutoEncoder(init_features=8)
    dem_model_16 = AutoEncoder(init_features=16)
    dem_model_32 = AutoEncoder(init_features=32)
    dem_model_64 = AutoEncoder(init_features=64)

    #Initiate callbacks
    checkpoint_callback = ModelCheckpoint(monitor="val_loss", save_last=True)

    #Initiate trainer
    trainer = pl.Trainer(gpus=1, max_epochs=1000, callbacks=checkpoint_callback)

    #Train model
    trainer.fit(dem_model_8, train_loader, val_loader)
    trainer.fit(dem_model_16, train_loader, val_loader)
    trainer.fit(dem_model_32, train_loader, val_loader)
    trainer.fit(dem_model_64, train_loader, val_loader)

if __name__ == "__main__":
    dem_training()

