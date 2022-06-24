import pytorch_lightning as pl
from loss import MAELossHole
import torch 
from model import UNet

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
