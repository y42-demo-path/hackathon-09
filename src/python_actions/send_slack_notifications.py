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
    most_recent_data = gaps[gaps['PROCESSED_AT'] == most_recent_date]
    high_official_gap = most_recent_data[most_recent_data['IS_HIGH_OFFICIAL_GAP']] 

    # Check if there are any high revenue items. If so, proceed with the notification.
    if not high_official_gap.empty:
        # Send a POST request to the Slack webhook URL with the message payload.

        for i, j in high_official_gap.iterrows():
            title = f"my {j['IS_HIGH_OFFICIAL_GAP']}. title"
            body = f"this is a random description based on the value of row {i}"

            my_obj = {title : body}

        #response = requests.post(webhook_url, json=my_obj, headers=headers)

        response = requests.post(webhook_url, json={"key_variable_defined_for_automation": "Hello from Y42"}, headers=headers)


        # Log the response status code, headers and text for debugging purposes.
        logging.info(response.status_code)
        logging.info(response.headers)
        logging.info(response.text)

