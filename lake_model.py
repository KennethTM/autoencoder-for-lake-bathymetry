import random
import os
from torch.utils.data import DataLoader
import pytorch_lightning as pl
from pytorch_lightning.callbacks import ModelCheckpoint
from pytorch_lightning.loggers import TensorBoardLogger
from lightning_module import AutoEncoder
from helpers import lake_aug
from data_classes import Lakes
import argparse 
import pickle

pl.seed_everything(9999)
random.seed(9999)

#Define main function
def main(buffer, weights):

    buffer_dir = "data/buffer_{}_percent".format(buffer)

    #Import lake dict
    with open(os.path.join(buffer_dir, "lakes_dict.pickle"), 'rb') as src:
        lakes_dict = pickle.load(src)

    train_list = lakes_dict["train"]
    valid_list = lakes_dict["valid"]

    train_ds = Lakes(train_list, lake_aug)
    valid_ds = Lakes(valid_list)

    train_loader = DataLoader(train_ds, batch_size=1, num_workers=0, shuffle = True)
    valid_loader = DataLoader(valid_ds, batch_size=1, num_workers=0, shuffle = False)

    if weights == "random":
        lake_model = AutoEncoder()
    else:
        weights_path = "lightning_logs/dem_models/{}/checkpoints/last.ckpt".format(weights)
        lake_model = AutoEncoder.load_from_checkpoint(weights_path)

    #Checkpoint based on best validation loss
    checkpoint_callback = ModelCheckpoint(monitor="val_loss", save_last=True)

    #Experiment version naming
    logger = TensorBoardLogger("lightning_logs", name="lake_models", version="buffer_{}_weights_{}".format(buffer, weights))

    #Initiate trainer
    trainer = pl.Trainer(gpus=1, max_epochs=500, callbacks=checkpoint_callback, accumulate_grad_batches=8, logger=logger, precision=16)

    #Train model
    trainer.fit(lake_model, train_loader, valid_loader)

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Train lake model from different inital weights")
    parser.add_argument("buffer", type = str, help="Buffer distance used for crop, one of 33, 66 or 100")
    parser.add_argument("weights", type = str, help="Initial weights used for training, one of 'random', 'dem_8', 'dem_16', 'dem_32', or  'dem_64'")
    arguments = parser.parse_args()

    main(arguments.buffer, arguments.weights)
