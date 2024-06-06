import json
import pandas as pd

import requests

from y42.v1.decorators import data_action
import logging

# use the @data_action decorator to trigger actions in third party systems
# make sure you have a corresponding .yml exposure definition matching the function's name
# for more information check out our docs: https://www.y42.com/docs/python-actions

@data_action
def business_alert(context,assets):
    # Define the Slack webhook URL to which the notification will be sent.
    webhook_url = context.secrets.get("slack_webhook_url")
    headers={'Content-Type': 'application/json'}
    
    # Reference the 'mrt_gaps_by_exchange_rate' dataset from Y42 assets.
    gaps = assets.ref('mrt_gaps_by_exchange_rate')

    # Business logic: 
    # Filter by the most recent date and where the condition that the gap is high is satisfied.
    most_recent_date = gaps['PROCESSED_AT'].max()
    
    most_recent_data = gaps[
        (gaps['PROCESSED_AT'] == most_recent_date) & 
        (gaps['EXCHANGE_RATE_NAME'] != 'Tourist Dollar')
    ]
    
    df_filtered = most_recent_data[(most_recent_data['IS_TOP_CRIPTO_EXCHANGES']) | 
                                (~most_recent_data['SOURCE_REFERENCE'].isin(['Criptoya - Cripto']))]


    result = df_filtered[['EXCHANGE_RATE_NAME', 'TOTAL_BID_PRICE', 'CHANGE_TOTAL_BID_PRICE']]
    result['CHANGE_TOTAL_BID_PRICE'] = (result['CHANGE_TOTAL_BID_PRICE'] * 100).round(2)

    result = result.sort_values(by='SOURCE_REFERENCE')
        
    body = result.to_html()
    
    #response = requests.post(webhook_url, json={"body": body}, headers=headers)
    
    # Log the response status code and headers for debugging purposes.
    logging.info(body)

    
