import pandas as pd
import yfinance as yf
import logging
import json

from y42.v1.decorators import data_loader

@data_loader
def raw_ccl_usd_ars(context) -> pd.DataFrame:
    tickers = ['GGAL.BA', 'GGAL', 'YPFD.BA', 'YPF', 'PAMP.BA', 'PAM']
    data = pd.DataFrame(columns=tickers)
    df = pd.DataFrame()

    for ticker in tickers:
        data[ticker] = yf.download(ticker, period='1d', interval='5m')['Adj Close']
        # Select the last available value
        data = data.iloc[[-1]]

    # Calculation of the CCL dollar as the average of the CCL of GGAL, PAM, and YPF
    df['GGAL_CCL'] = data['GGAL.BA'] * 10 / data['GGAL']
    df['YPF_CCL'] = data['YPFD.BA'] * 1 / data['YPF']
    df['PAMP_CCL'] = data['PAMP.BA'] * 25 / data['PAM']
    df['CCL_AVERAGE'] = (df['GGAL_CCL'] + df['YPF_CCL'] + df['PAMP_CCL']) / 3
    df = df.reset_index().fillna(0)
    df.columns = df.columns.str.upper()

    #df['DATETIME'] = pd.to_numeric(df['DATETIME'], errors='coerce')
    df['DATETIME'] = df['DATETIME'].astype(int)   
    
    return df
