import pytorch_lightning as pl
from loss import MAELossHole
import torch 
from model import UNet
from helpers import dem_inv_scale

class AutoEncoder(pl.LightningModule):
    def __init__(self, init_features = 8, lr = 1e-4):
        super().__init__()
        
        self.save_hyperparameters()
                
        self.lr = lr
                
        self.unet = UNet(in_channels=1, out_channels=1, mask_channels=1, init_features=init_features)
        
        self.loss = MAELossHole()

    def forward(self, x_in, x_mask):
        x_hat = self.unet(x_in, x_mask)
        return x_hat

    def configure_optimizers(self):
        optimizer = torch.optim.Adam(self.parameters(), lr=self.lr)
        return optimizer

    def training_step(self, train_batch, batch_idx):
        x_in, x_obs, x_mask = train_batch
        x_hat = self.unet(x_in, x_mask)
        loss = self.loss(x_hat, x_obs, x_mask)
        self.log('train_loss', loss, on_epoch=True, prog_bar=True)
        return {'loss': loss}

    def validation_step(self, val_batch, batch_idx):
        x_in, x_obs, x_mask = val_batch
        x_hat = self.unet(x_in, x_mask)
        loss = self.loss(x_hat, x_obs, x_mask)
        self.log('val_loss', loss, on_epoch=True, prog_bar=True)

        x_hat_original_scale = dem_inv_scale(x_hat)
        x_obs_original_scale = dem_inv_scale(x_obs)
        loss_original_scale = self.loss(x_hat_original_scale, x_obs_original_scale, x_mask)
        self.log('val_loss_original_scale', loss_original_scale, on_epoch=True)
