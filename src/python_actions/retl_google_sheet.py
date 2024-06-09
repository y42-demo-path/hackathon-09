import json
import pandas as pd

import requests

from y42.v1.decorators import data_action
import logging
from google.oauth2 import service_account
import logging
import gspread

@data_action
def retl_mart_gsheet(context, assets):

    df = assets.ref('mrt_gaps_by_exchange_rate')
    # turn all columns to type string
    for column in df.columns.tolist():
        df[column] = df[column].astype(str)
    
    # load credentials & authorize
    SCOPES = ('https://www.googleapis.com/auth/spreadsheets', 'https://www.googleapis.com/auth/drive')
    service_account_info = json.loads(context.secrets.get(service_account_info))
    my_credentials = service_account.Credentials.from_service_account_info(service_account_info, scopes=SCOPES)

    client = gspread.authorize(my_credentials)
    logging.info('authorized')

    # connect to sheet by ID and sync data
    sht1 = client.open_by_key('1p8Rajxx5f490urjZGIUR0qbkI6bJHom-z3JVObqyUcI')
    worksheet = sht1.get_worksheet(0)
    logging.info('connected to sheet')
    data = [df.columns.to_numpy().tolist()] + df.to_numpy().tolist() # this works when all columns are of type string
    worksheet.update(data)
    logging.info('data updated')
