import requests
import pandas as pd
import logging
import json

from y42.v1.decorators import data_loader

@data_loader
def raw_criptoya_usd_ars(context) -> pd.DataFrame:
    url = "https://criptoya.com/api/dolar"
    r = requests.get(url)
    
    if r.status_code == 200:
        data = r.json()
        df = pd.DataFrame(data)
        df = df[['ahorro', 'tarjeta', 'blue']]
        df = df[df.index.isin(['price', 'timestamp', 'ask', 'bid'])].fillna(0)
        df = df.T.reset_index()
    else: 
        logging.error(f"An error occurred. Error status_code: {r.status_code}")
    
    return df


@data_loader
def raw_criptoya_usdt_ars(context) -> pd.DataFrame:
    url = "https://criptoya.com/api/usdt/ars/100"
    r = requests.get(url)
    
    if r.status_code == 200:
        data = r.json() 
        df = pd.DataFrame(data)
        df = df.T.reset_index()
    else: 
        logging.error(f"An error occurred. Error status_code: {r.status_code}")
    
    return df
