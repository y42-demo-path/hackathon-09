import json
import pandas as pd
import requests
from tabulate import tabulate

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
        (~gaps['EXCHANGE_RATE_NAME'].isin(['Tourist Dollar', 'Saving Dollar']))
    ]
    
    filtered_data = most_recent_data[(most_recent_data['IS_TOP_CRIPTO_EXCHANGES']) | 
                                (~most_recent_data['SOURCE_REFERENCE'].isin(['Criptoya - Cripto']))]


    general_exchange_report = filtered_data[['EXCHANGE_RATE_NAME', 'TOTAL_BID_PRICE', 'CHANGE_TOTAL_BID_PRICE']]
    general_exchange_report['TOTAL_BID_PRICE'] = round(general_exchange_report['TOTAL_BID_PRICE'], 2)
    general_exchange_report['CHANGE_TOTAL_BID_PRICE'] = round(general_exchange_report['CHANGE_TOTAL_BID_PRICE'] * 100, 2)
    general_exchange_report = general_exchange_report.sort_values(by='TOTAL_BID_PRICE', ascending = False)
    general_exchange_report = general_exchange_report.rename(
        columns={
            'EXCHANGE_RATE_NAME': 'Exchange Rate Name', 
            'TOTAL_BID_PRICE': 'Bid price', 
            'CHANGE_TOTAL_BID_PRICE': '% Bid price'
        }
    )
    general_exchange_report = general_exchange_report.set_index('Exchange Rate Name')
    
    table_format = tabulate(
        general_exchange_report, 
        headers='keys', 
        tablefmt='pretty', 
        colalign=("left","center", "center"), 
        numalign="center",
        floatfmt=".2f"
    )
    
    body = f"""Today's dollar exchange rates:

    {table_format}
    """

    response = requests.post(webhook_url, json={"body": body}, headers=headers)
    logging.info(response.status_code)
    logging.info(response.headers)

    high_official_gap = most_recent_data[most_recent_data['IS_HIGH_OFFICIAL_GAP']]
    high_official_mep = most_recent_data[most_recent_data['IS_HIGH_MEP_GAP']]
    
    is_arbitrage_opportunity_filtered = most_recent_data[
        (most_recent_data['SOURCE_REFERENCE'] == 'Criptoya - Cripto') & 
        (most_recent_data['IS_TOP_CRIPTO_EXCHANGES'] == True)
    ]
    
    is_arbitrage_opportunity = is_arbitrage_opportunity_filtered[
        is_arbitrage_opportunity_filtered['IS_ARBITRAGE_OPPORTUNITY']
    ]
    
    change_bid_price = most_recent_data[most_recent_data['IS_HIGH_CHANGE_TOTAL_BID_PRICE'] == True]
        
    if not high_official_gap.empty:
        # Send a POST request to the Slack webhook URL with the message payload.

        for i, j in high_official_gap.iterrows():

            exchange_name = j['EXCHANGE_RATE_NAME']
            official_gap_value = round(j['GAP_OVER_OFFICIAL_WHOLESALE_EXCHANGE_RATE'] * 100, 2)

            body = f"The {exchange_name} has a gap over the official exchange rate of: {official_gap_value}%"
          
            response = requests.post(webhook_url, json={"body": body}, headers=headers)
            
            # Log the response status code and headers for debugging purposes.
            logging.info(response.status_code)
            logging.info(response.headers)

    if not high_official_mep.empty:
        # Send a POST request to the Slack webhook URL with the message payload.

        for i, j in high_official_gap.iterrows():

            exchange_name = j['EXCHANGE_RATE_NAME']
            mep_gap_value = round(j['GAP_OVER_MEP_EXCHANGE_RATE'] * 100, 2)

            body = f"The {exchange_name} has a gap over the MEP exchange rate of: {mep_gap_value}%"

            response = requests.post(webhook_url, json={"body": body}, headers=headers)
            
            # Log the response status code and headers for debugging purposes.
            logging.info(response.status_code)
            logging.info(response.headers)


    if not is_arbitrage_opportunity.empty:
        # Send a POST request to the Slack webhook URL with the message payload.
        
        is_arbitrage_opportunity = is_arbitrage_opportunity.sort_values(
            by='ARBITRAGE_RATIO', 
            ascending = False
        ).head(1) 

        for i, j in is_arbitrage_opportunity.iterrows():

            exchange_name = j['EXCHANGE_RATE_NAME']
            arbitrage_value = round(j['ARBITRAGE_RATIO'] * 100, 2)

            body = f"The {exchange_name} has a arbitrage opportunity of: {arbitrage_value}%"

            response = requests.post(webhook_url, json={"body": body}, headers=headers)
            
            # Log the response status code and headers for debugging purposes.
            logging.info(response.status_code)
            logging.info(response.headers)

    if not change_bid_price.empty:
        # Send a POST request to the Slack webhook URL with the message payload.
        
        for i, j in change_bid_price.iterrows():

            exchange_name = j['EXCHANGE_RATE_NAME']
            increase_percentage = round(j['CHANGE_TOTAL_BID_PRICE'] * 100, 2)

            current_value = round(j['TOTAL_BID_PRICE'], 2)
            previous_value = round(j['TOTAL_BID_PRICE_LAGGED'], 2)

            body = (
                f"{exchange_name} --> The price of the dollar (bid) has risen {increase_percentage}% "
                f"(from ${previous_value} to ${current_value}) in the last 30 minutes."
            )

            response = requests.post(webhook_url, json={"body": body}, headers=headers)
            
            # Log the response status code and headers for debugging purposes.
            logging.info(response.status_code)
            logging.info(response.headers)


