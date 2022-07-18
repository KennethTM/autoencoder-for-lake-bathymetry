import subprocess

#Train DEM models of different complexity (initial_features)

def main():
    init_features_list = [8, 16, 32, 64]

    for i in init_features_list:
        subprocess.call(["python", "dem_model.py", str(i)])

if __name__ == "__main__":
    main()
