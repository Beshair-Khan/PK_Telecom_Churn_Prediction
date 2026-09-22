import os
import pandas as pd
def load_csv(data_dir="../data"):
    dfs={}
    for files in os.listdir(data_dir):
        name=files.replace(".csv","")
        dfs[name]=pd.read_csv(os.path.join(data_dir,files))
    return dfs

