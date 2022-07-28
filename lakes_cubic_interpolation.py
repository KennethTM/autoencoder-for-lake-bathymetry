import os 
import pickle
import numpy as np
import rasterio as rio
from scipy.interpolate import griddata

#Predict lake bathymetry using cubic interpolation and write to file for visual comparison
def main():

    best_buffer = '100'
    best_buffer_dir = "data/buffer_{}_percent".format(best_buffer)

    #Load data
    with open(os.path.join(best_buffer_dir, "lakes_dict.pickle"), 'rb') as src:
        lakes_dict = pickle.load(src)

    #Predict for all lakes
    for p in ["train", "valid", "test"]:
        
        for i in lakes_dict[p]:
            
            id = i["id"]
            dem = i["lake"]
            mask = i["mask"]

            xy = np.argwhere(mask == 0)
            z = dem[mask == 0]
            xy_hat = np.argwhere(mask == 1)
            
            hat = griddata(xy, z, xy_hat, method = "cubic")

            mask_copy = mask.copy()
            mask_copy[xy_hat[:,0], xy_hat[:,1]] = hat
            profile = i["profile"]

            pred_path = os.path.join(best_buffer_dir, "lakes_cubic", "lake_{}.tif".format(id))

            with rio.open(pred_path, 'w', **profile) as dst:
                dst.write(mask_copy, 1)

if __name__ == "__main__":
    main()
