import subprocess
from helpers import init_features_list

#Train DEM models of different complexity (initial_features)

def main():

    for i in init_features_list:
        subprocess.call(["python", "dem_model.py", str(i)])

if __name__ == "__main__":
    main()
