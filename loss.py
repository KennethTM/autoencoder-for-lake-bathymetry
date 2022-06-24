import torch.nn as nn

#Loss functions 

class MSELossWeighted(nn.Module):
    def __init__(self, w_hole = 10, w_nonhole = 1):
        super().__init__()
        self.l2 = nn.MSELoss()
        self.w_hole = w_hole
        self.w_nonhole = w_nonhole

    def forward(self, hat, obs, mask):
        
        l2_hole = self.l2(hat[mask == 1], obs[mask == 1])
        l2_nonhole = self.l2(hat[mask == 0], obs[mask == 0])
        
        l2_total = (l2_hole*self.w_hole) + (l2_nonhole*self.w_nonhole)

        return l2_total
    
class MAELossWeighted(nn.Module):
    def __init__(self, w_hole = 10, w_nonhole = 1):
        super().__init__()
        self.l1 = nn.L1Loss()
        self.w_hole = w_hole
        self.w_nonhole = w_nonhole

    def forward(self, hat, obs, mask):
        
        l1_hole = self.l1(hat[mask == 1], obs[mask == 1])
        l1_nonhole = self.l1(hat[mask == 0], obs[mask == 0])
        
        l1_total = (l1_hole*self.w_hole) + (l1_nonhole*self.w_nonhole)

        return l1_total
    
class MAELossHole(nn.Module):
    def __init__(self):
        super().__init__()
        self.l1 = nn.L1Loss()

    def forward(self, hat, obs, mask):
        
        l1_hole = self.l1(hat[mask == 1], obs[mask == 1])

        return l1_hole 
