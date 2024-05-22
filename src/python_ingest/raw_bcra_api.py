import requests
import pandas as pd
import logging
import json

from y42.v1.decorators import data_loader

@data_loader
def raw_bcra_api(context) -> pd.DataFrame:
    url = "https://api.bcra.gob.ar/estadisticas/v2.0/principalesvariables"
    headers = {"Accept-Language": "en-US"}
    
    r = requests.get(url, headers=headers, verify=False)
    
    if r.status_code == 200:
        data = r.json() 
        df = pd.DataFrame(data['results'])
    else: 
        logging.error(f"An error occurred. Error status_code: {r.status_code}")
    
    return df
