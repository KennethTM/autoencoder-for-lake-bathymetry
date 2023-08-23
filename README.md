## Project: autoencoder-for-lake-bathymetry

### Predicting lake bathymetry from the topography of the surrounding terrain using deep learning

Repository containing code, data, model weights, and example notebook for manuscript titled *Predicting lake bathymetry from the topography of the surrounding terrain using deep learning* published in *Limnology and Oceanography: Methods* (DOI: 10.1002/lom3.10573).

Python version 3.8 and R version >4.0. See the 'requirements.txt' file for specific Python package versions used for the analysis.

See **Example notebook.ipynb** for a demonstration of using the model and example data provided in here. Download this GitHub repository as a '.zip', extract the contents, and open the Jupyter Notebook file. To run the notebook, install the following Python packages: *torch* (deep learning library), *rasterio* (geographic data handling), and optionally *matplotlib* for plotting.

<p align="center">
  <b>Example of ground truth and predicted lake bathymetry</b><br>
  <br>
  <img src="https://github.com/KennethTM/autoencoder-for-lake-bathymetry/blob/main/gifs/6_obs_small.gif">
  <br>
  <img src="https://github.com/KennethTM/autoencoder-for-lake-bathymetry/blob/main/gifs/6_pred_small.gif">
</p>
