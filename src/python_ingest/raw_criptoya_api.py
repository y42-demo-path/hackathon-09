import requests
import pandas as pd
import logging
import json

from y42.v1.decorators import data_loader

@data_loader
def raw_exchange_rates_other_usd_ars(context) -> pd.DataFrame:
    url = "https://criptoya.com/api/dolar"
    r = requests.get(url)
    
    if r.status_code == 200:
        data = r.json()
        df = pd.DataFrame(data)
        df = df[['ahorro', 'tarjeta', 'blue']]
        df = df[df.index.isin(['price', 'timestamp', 'ask', 'bid'])]
        df = df.T.reset_index()
    else: 
        logging.error(f"An error occurred. Error status_code: {r.status_code}")
    
    return df


@data_loader
def raw_exchange_rates_cripto_usdt_ars(context) -> pd.DataFrame:
    url = "https://criptoya.com/api/usdt/ars/100"
    r = requests.get(url)
    
    if r.status_code == 200:
        data = r.json() 
        df = pd.DataFrame(data)
        df = df.T.reset_index()
    else: 
        logging.error(f"An error occurred. Error status_code: {r.status_code}")
    
    return df

@data_loader
def raw_exchange_rates_mep_usd_ars(context) -> pd.DataFrame:
    url = "https://criptoya.com/api/dolar"
    r = requests.get(url)
    
    if r.status_code == 200:
        data = r.json() 
        mep_al30_ci = data["mep"]["al30"]['ci']
        mep_gd30_ci = data["mep"]["gd30"]['ci']
        mep_lede_ci = data["mep"]["lede"]['ci']

        mep_al30_48hs = data["mep"]["al30"]['48hs']
        mep_gd30_48hs = data["mep"]["gd30"]['48hs']
        mep_lede_48hs = data["mep"]["lede"]['48hs']

        data = {
            "MEP al30 CI": mep_al30_ci,
            "MEP gd30 CI": mep_gd30_ci,
            "MEP lede CI": mep_lede_ci,
            "MEP al30 48 hs": mep_al30_48hs,
            "MEP gd30 48 hs": mep_gd30_48hs,
            "MEP lede 48 hs": mep_lede_48hs,
        }

        df = pd.DataFrame(data)
        df = df.T.reset_index()
    else: 
        logging.error(f"An error occurred. Error status_code: {r.status_code}")
    
    return df
