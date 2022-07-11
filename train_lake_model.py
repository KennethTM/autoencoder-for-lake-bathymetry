import subprocess

#Train lakes models using different combinations of initial weights and buffer distances

def main():
    weights_list = ['random', 'dem_8', 'dem_16', 'dem_32',  'dem_64']
    buffer_list = ['33', '66', '100']

    grid_list = [(b, w) for b in buffer_list for w in weights_list]

    for b, w in grid_list:
        subprocess.call(["python", "lake_model.py", b, w])

if __name__ == "__main__":
    main()
