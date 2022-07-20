import torch.nn as nn

#Loss function - L1 for hole region only
class MAELossHole(nn.Module):
    def __init__(self):
        super().__init__()
        self.l1 = nn.L1Loss()

    def forward(self, hat, obs, mask):
        
        l1_hole = self.l1(hat[mask == 1], obs[mask == 1])

        return l1_hole 
