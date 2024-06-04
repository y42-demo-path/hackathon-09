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
    webhook_url = "https://hooks.slack.com/services/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"
    
    # Reference the 'mrt_completed_orders' dataset from Y42 assets.
    gaps = assets.ref('mrt_gaps_by_exchange_rate')

    # Business logic: 
    # Filter for high revenue items, defined as those with a total amount greater than 10,000.
    high_official_gap = gaps[gaps['is_high_official_gap']]

    # Check if there are any high revenue items. If so, proceed with the notification.
    if not high_official_gap.empty:
        # Send a POST request to the Slack webhook URL with the message payload.
        response = requests.post(webhook_url, json={"key_variable_defined_for_automation": "Hello from Y42"}, headers={'Content-Type': 'application/json'})
        
        # Log the response status code and headers for debugging purposes.
        logging.info(response.status_code)
        logging.info(response.headers)
