## Project: autoencoder-for-lake-bathymetry

Repository containing code, data, model weights, and example notebook for manuscript titled *Predicting lake bathymetry from the topography of the surrounding terrain using deep learning*.

Python version 3.8 and R version >4.0.
See 'requirements.txt' file for Python package versions used for analysis.

See **Example notebook.ipynb** for a demonstration of using the model and example data provided in here. Download the GitHub repository as a '.zip', extract the contents, and open the Jupyter Notebook. To run the notebook install the following Python packages: *torch* (deep learning library), *rasterio* (geographic data handling), and optionally *matplotlib* for plotting.

*Example of ground truth and predicted lake bathymetry*

![Ground truth lake bathymetry](https://github.com/KennethTM/autoencoder-for-lake-bathymetry/blob/main/gifs/6_obs_small.gif)

![Predicted lake bathymetry](https://github.com/KennethTM/autoencoder-for-lake-bathymetry/blob/main/gifs/6_pred_small.gif)
