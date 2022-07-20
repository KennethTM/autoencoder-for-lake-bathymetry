import subprocess
from helpers import buffer_list, weights_list, init_features_list

#Train lakes models using different combinations of initial weights and buffer distances

def main():

    #Create hyperparameter grid
    grid_list = [(b, w, f) for b in buffer_list for w in weights_list for f in init_features_list]

    for b, w in grid_list:
        subprocess.call(["python", "lake_model.py", b, w])

if __name__ == "__main__":
    main()
