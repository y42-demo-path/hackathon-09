# 💸 Monitoring Parallel Market Exchange Rate in Argentina 
## Introduction

The goal of this project was to monitor the premium among several exchange rates in Argentina in near real-time. Tracking the differences amoung the official exchange rate and the free market dollars is crucial because it reflects devaluation expectations. As economic agents make anticipatory decisions, any significant deviation can impact other economic variables, such as inflation. It is important to mention that the foreign exchange market remains controlled despite the new government, and the regulations and restrictions remain quite similar to those of the previous government.

To achieve this, exchange rate data was extracted from several APIs (**BCRA, Criptoya, Yahoo Finance**) using Python ingestors available on Y42. The necessary transformations (stage models) were then performed, and a final model (mart) was created where all the required metrics were stored. Subsequently, customized alerts were sent to **Slack** via webhook. The pipeline ran every 30 minutes during Argentina's operating hours (from 11 AM to 6 PM). Additionally, the mart model data was sent to a Google Sheet for visualization purposes.

## ⚙️ Data Pipeline
This was the pipeline that was implemented. The `raw` models performed the data ingestion, the stage (`stg_`) models handled necessary transformations such as renaming, filtering, pivoting, and adding new columns. The intermediate (`int_`) model joined the stage models to obtain all exchange rates in a single model, and the `mrt` model calculated the metrics. Finally, the Python actions sent alerts to **Slack** and **Google Sheet**.

![dag](https://github.com/y42-demo-path/hackathon-09/assets/67651418/2632781b-a757-4a41-a95f-f0370c5082d4)


Below is a detailed explanation of each model:

#### 🏦Source

For all sources, we use the Python Source to fetch data from the API using a Python script.

- **raw_bcra_api**: The official exchange rates (wholesale and retailer) were extracted using the Central Bank of Argentina's [API](https://www.bcra.gob.ar/BCRAyVos/catalogo-de-APIs-banco-central.asp).
- **raw_criptoya_api**: This [API](https://criptoya.com/api) provided the crypto dollar (USDT), MEP (Electronic Payment Market), savings dollar, tourist dollar, and blue dollar (or black market). Two different endpoints were used:
  - **Cryptocurrency query** (`/api/{coin}/{fiat}/{volume}`): The **USDT/ARS** pair for all existing exchanges in Argentina (around 30) was obtained here.
  - **Other dollars** (`/api/dolar`): The rest of the exchange rates were obtained here. The MEP had a more complex structure, so it was extracted in a different model.
- **raw_yahoofinance_api**: The CCL (Dólar Contado con Liquidación) exchange rate was obtained using the **Yahoo Finance** library. Data for calculating the CCL was fetched from **Banco Galicia, PAMPA, and YPF**.

> It is important to note that these APIs provide the latest available information for each exchange rate, not historical price data.

#### 🏗️ Transformations 

Several stage models handle data transformations from the source. Below is an explanation of each:

- **stg_exchange_rates_ccl_usd_ars**: Since CCL calculations come from columns, an unpivot using the dbt macro was performed to convert them to rows. New fields were added and others were casted.
- **stg_exchange_rates_cripto_usdt_ars**: The names of the exchanges were mapped to appropriate names using a new macro called `map_values_from_seed`. As in the previous case, new fields and some averages for bid and ask prices were added.
- **stg_exchange_rates_mep_usd_ars**: Renames were done, and new average fields were added.
- **stg_exchange_rates_official_usd_ars**: Only the indicators needed were filtered, renamed, and new fields were added. The API provided other economic indicators as well.
- **stg_exchange_rates_other_usd_ars**: A variable (dollars_descriptions) was created to rename some names and add descriptions for these variables. A `for` loop in Jinja was used to iterate over the variable, adhering to the DRY principle.
- **int_exchange_rates_unioned**: A model was created that joined all the stage models, allowing all the exchange rates needed to be in a single model. The `union_relations` macro from dbt facilitated this task. Since the data were immutable event streams, an incremental model was created to append data to this table every run, maintaining historical information in this model.

#### 📊 Analytics

-   **mrt_gaps_by_exchange_rate**: In this model, all the metrics of interest for sending alerts to Slack were created. Metrics measuring the gap amoung all exchange rates and official dollars (retailer and wholesale), MEP, Blue, etc., were created, along with boolean variables to check if the gaps exceeded certain thresholds. Additionally, price variations from the last available value were added to detect abrupt price changes. Metrics to capture arbitrage opportunities were also included.

> 💡 **dbt macros used:** 
>  - `dbt_utils.unpivot`
>  - `dbt_utils.get_column_values`
>  - `dbt_utils.generate_surrogate_key`
>  - `dbt_utils.safe_divide`

#### 🚨Actions

-   **send_slack_notifications**: A connection to send all the custom alerts to be monitored is set up. For example, an alert is received when the gap with the official exchange rate exceeds **45%**, or when there is a price increase greater than **1%** from the last run. Additionally, notifications are received when there is an arbitrage opportunity for the **USDT/ARS** pair among crypto exchanges. Finally, a summary table of the main rates is sent to the channel.

![slack 1](https://github.com/y42-demo-path/hackathon-09/assets/67651418/13f28933-5d3d-406e-9128-c4c3422d8433)

![slack 2](https://github.com/y42-demo-path/hackathon-09/assets/67651418/b5850752-9bc9-4693-b7a6-a02dc58514cc)


-   **retl_google_sheet**: As Snowflake credentials were not available, an R-ETL process was created to send data to a Google Sheet, allowing for any additional analytical analysis (charts, pivot tables, etc.). Kudos to **Rob** for providing this piece of code.
  
#### 📈 Visualizations and Analysis 

Using the data available in Google Sheets, several charts were created and included in a [Notion document](https://grizzled-squid-ff4.notion.site/Analysis-of-the-Argentine-Exchange-Rate-Market-02f61df72eaa433993fbeda328c2c4c4). This document highlights the key insights derived from the data.

![image](https://github.com/y42-demo-path/hackathon-09/assets/67651418/0f2ab013-b74f-4c0c-b770-521ad2e5ad10)



#### 📑 Quality Testing and Descriptions

Tests were created to ensure that IDs were unique and did not contain null values, as well as tests for other important fields. Recency tests were also placed on the main models to verify that the ingested information was the latest available. Additionally, all models and their columns were documented.

#### 🖹 Documentation

-   [Python Sources](https://www.y42.com/docs/python-sources)
-   [BCRA's API](https://www.bcra.gob.ar/BCRAyVos/catalogo-de-APIs-banco-central-i.asp)
-   [Criptoya's API](https://criptoya.com/api)
-   [Yahoo Finance library](https://pypi.org/project/yfinance/)
-   [Differences between MEP and CCL](https://finco.com.ar/productos/dolar-mep-y-ccl/)
-   [Send Slack Notifications](https://www.y42.com/docs/python-actions/send-slack-notifications)
-   [dbt utils](https://github.com/dbt-labs/dbt-utils)
- [Notifications Alert Channel](https://exchangeraten-lky6868.slack.com/archives/C0768D5U9K3)
- [Google Sheet Link](https://docs.google.com/spreadsheets/d/1p8Rajxx5f490urjZGIUR0qbkI6bJHom-z3JVObqyUcI/edit?gid=0#gid=0)
- [Notion Document with Analysis](https://grizzled-squid-ff4.notion.site/Analysis-of-the-Argentine-Exchange-Rate-Market-02f61df72eaa433993fbeda328c2c4c4)
- [Y42 Feedback](https://docs.google.com/document/d/1muiGE6DlbrxAiXuAAR_0l87OWn-LNXj8AVtpaHfMpYM/edit)
