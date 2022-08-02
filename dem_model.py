import numpy as np
import random
from torch.utils.data import DataLoader
import pytorch_lightning as pl
from pytorch_lightning.callbacks import ModelCheckpoint
from pytorch_lightning.loggers import TensorBoardLogger
from lightning_module import AutoEncoder
from helpers import dem_scale
from data_classes import DEMTrain, DEMValid
import argparse 

pl.seed_everything(9999)
random.seed(9999)

#Define main function
def main(init_features):

    #Load DEM data
    data = np.load("data/data.npz")
    dem_data = dem_scale(data["dem"])

    train = dem_data[:8000]
    valid = dem_data[8000:]

    #Load mask data
    random_mask = np.load("data/lakes_random.npz")
    mask_data = random_mask["mask"].astype("float32")

    random_mask_idx = random.choices(range(mask_data.shape[0]), k=valid.shape[0])
    valid_mask = mask_data[random_mask_idx]

    #Create datasets
    train_dataset = DEMTrain(train, mask_data)
    valid_dataset = DEMValid(valid, valid_mask)

    #Create dataloaders
    train_loader = DataLoader(train_dataset, batch_size=32, num_workers=0, shuffle=True)
    val_loader = DataLoader(valid_dataset, batch_size=32, num_workers=0, shuffle=False)

    #Initiate model
    dem_model = AutoEncoder(init_features=init_features)

    #Initiate callbacks
    checkpoint_callback = ModelCheckpoint(monitor="val_loss", save_last=True)
    
    #Experiment version naming
    logger = TensorBoardLogger("lightning_logs", name="dem_models", version="dem_{}".format(str(init_features)))

    #Initiate trainer
    trainer = pl.Trainer(gpus=1, max_epochs=1000, callbacks=checkpoint_callback, logger=logger)

    #Train model
    trainer.fit(dem_model, train_loader, val_loader)

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Train DEM model with X initial features")
    parser.add_argument("init_features", type = int, help="Number of initial features in Unet")
    arguments = parser.parse_args()

    main(arguments.init_features)
