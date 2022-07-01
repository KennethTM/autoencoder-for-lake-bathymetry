import pandas as pd
import pickle
import numpy as np
import scipy
import cv2

#Compute lake summary statistics

with open('data/buffer_33_percent/lakes_dict.pickle', 'rb') as src:
    lakes_dict = pickle.load(src)

result_list = []

splits = ["train", "valid", "test"]

for s in splits:

    lakes = lakes_dict[s]

    for i in lakes:


x = lakes_dict["train"][0]

#https://docs.opencv.org/4.x/df/d3d/tutorial_py_inpainting.html

#https://stackoverflow.com/questions/37662180/interpolate-missing-values-2d-python