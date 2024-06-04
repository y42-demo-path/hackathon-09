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
    most_recent_data = gaps[(gaps['PROCESSED_AT'] == most_recent_date) & (gaps['EXCHANGE_RATE_NAME'] != 'Tourist Dollar')]
    
    
    high_official_gap = most_recent_data[most_recent_data['IS_HIGH_OFFICIAL_GAP']] 
    high_official_mep = most_recent_data[most_recent_data['IS_HIGH_MEP_GAP']] 

    
    is_arbitrage_opportunity_filtered = most_recent_data[(most_recent_data['SOURCE_REFERENCE'] == 'Criptoya - Cripto') & (most_recent_data['IS_TOP_CRIPTO_EXCHANGES'] == True)]
    is_arbitrage_opportunity = is_arbitrage_opportunity_filtered[is_arbitrage_opportunity_filtered['IS_ARBITRAGE_OPPORTUNITY']] 

    change_bid_price = most_recent_data[most_recent_data['IS_HIGH_CHANGE_TOTAL_BID_PRICE'] == True] 
        

    # Check if there are any high revenue items. If so, proceed with the notification.
    if not high_official_gap.empty:
        # Send a POST request to the Slack webhook URL with the message payload.

        for i, j in high_official_gap.iterrows():

            exchange_name = j['EXCHANGE_RATE_NAME']
            official_gap_value = round(j['GAP_OVER_OFFICIAL_RETAILER_EXCHANGE_RATE'] * 100, 2)

            body = f"🚨 The {exchange_name} has a gap over the official exchange rate of: {official_gap_value}%"

            logging.info(body)

    if not high_official_mep.empty:
        # Send a POST request to the Slack webhook URL with the message payload.

        for i, j in high_official_gap.iterrows():

            exchange_name = j['EXCHANGE_RATE_NAME']
            mep_gap_value = round(j['GAP_OVER_MEP_EXCHANGE_RATE'] * 100, 2)

            body = f"🚨 The {exchange_name} has a gap over the MEP exchange rate of: {mep_gap_value}%"

            logging.info(body)


    if not is_arbitrage_opportunity.empty:
        # Send a POST request to the Slack webhook URL with the message payload.
        
        is_arbitrage_opportunity = is_arbitrage_opportunity.sort_values(by='ARBITRAGE_RATIO', ascending = False).head(1) 

        for i, j in is_arbitrage_opportunity.iterrows():

            exchange_name = j['EXCHANGE_RATE_NAME']
            arbitrage_value = round(j['ARBITRAGE_RATIO'] * 100, 2)

            body = f"💸 The {exchange_name} has a arbitrage opportunity of: {arbitrage_value}%"

            logging.info(body)

    if not change_bid_price.empty:
        # Send a POST request to the Slack webhook URL with the message payload.
        
        for i, j in change_bid_price.iterrows():

            exchange_name = j['EXCHANGE_RATE_NAME']
            increase_percentage = round(j['CHANGE_TOTAL_BID_PRICE'] * 100, 2)

            body = f"🚀 The price of the dollar has risen {increase_percentage}% on {exchange_name} exchange in the last 30 minutes."

            logging.info(body)


        # response = requests.post(webhook_url, json=body, headers=headers)

        # Log the response status code and headers for debugging purposes.
        # logging.info(response.status_code)
        # logging.info(response.headers)

