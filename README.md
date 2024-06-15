# 💸 Monitoring Parallel Market Exchange Rate in Argentina 
## Introduction

The goal of this project is to monitor the premium between various exchange rates in Argentina in near real-time. Tracking the differences between the official exchange rate and the free market dollars is crucial because it reflects devaluation expectations. As economic agents make anticipatory decisions, any significant deviation can impact other economic variables, such as inflation.

To achieve this, we will extract exchange rate data from various APIs (**BCRA, Criptoya, Yahoo Finance**) using Python ingestors available on Y42. We will then perform the necessary transformations (stage models) and create a final model (mart) where all the required metrics will be stored. Subsequently, we will send customized alerts to **Slack** via webhook. The pipeline will run every 30 minutes during Argentina's operating hours (from 11 AM to 6 PM). Additionally, we will send the mart model data to a Google Sheet for visualization purposes.

## ⚙️ Data Pipeline
This is the pipeline I have implemented. The `raw` models perform the data ingestion, the stage (`stg_`) models handle necessary transformations such as renaming, filtering, pivoting and adding new columns. The intermediate (`int_`) model joins the stage models to obtain all exchange rates in a single model, and the `mrt` model calculates the metrics. Finally, the Python actions send alerts to **Slack** and **Google Sheet**.

![dag](https://github.com/y42-demo-path/hackathon-09/assets/67651418/2632781b-a757-4a41-a95f-f0370c5082d4)


Below is a detailed explanation of each model:

#### 🏦Source

For all sources, we use the Python Source to fetch data from the API using a Python script.

-   **raw_bcra_api**: I extract the official exchange rates (wholesale and retailer) using the Central Bank of Argentina's [API](https://www.bcra.gob.ar/BCRAyVos/catalogo-de-APIs-banco-central.asp).
-   **raw_criptoya_api**: This [API](https://criptoya.com/api) provides the crypto dollar (USDT), MEP (Electronic Payment Market), savings dollar, tourist dollar, and blue dollar (or black market). We use two different endpoints:
    -   **Cryptocurrency query** (`/api/{coin}/{fiat}/{volume}`): Here, we obtain the **USDT/ARS** pair for all existing exchanges in Argentina (around 30).
    -   **Other dollars** (`/api/dolar`): Here, we get the rest of the exchange rates. The MEP has a more complex structure, so we extract it in a different model.
-   **raw_yahoofinance_api**: I obtain the CCL (Dólar Contado con Liquidación) exchange rate using the **Yahoo Finance** library. We fetch data for calculating the CCL from **Banco Galicia, PAMPA, and YPF**.

> It is important to note that these APIs provide the latest available information for each exchange rate, not historical price data.

#### 🏗️ Transformations 

Several stage models handle data transformations from the source. Below is an explanation of each:

-   **stg_exchange_rates_ccl_usd_ars**: Since CCL calculations come from columns, I perform an unpivot using the dbt macro to convert them to rows. New fields are added and others were casted.
-   **stg_exchange_rates_cripto_usdt_ars**: I mapped the names of the exchanges to appropriate names using a new macro called `map_values_from_seed`. As in the previous case, new fields and some averages for bid and ask prices are added.
-   **stg_exchange_rates_mep_usd_ars**: Renames were done, and new average fields were added.
-   **stg_exchange_rates_official_usd_ars**: I filtered only the indicators we need, rename them, and add new fields. The API provides other economic indicators as well.
-   **stg_exchange_rates_other_usd_ars**: I created a variable (dollars_descriptions) to rename some names and add descriptions for these variables. I used a `for` loop in Jinja to iterate over the variable, adhering to the DRY principle.
-   **int_exchange_rates_unioned**: I created a model that joins all the stage models, allowing us to have all the exchange rates we need in a single model. The union_relations macro from dbt facilitated this task. Since the data are immutable event streams, I created an incremental model to append data to this table every run, maintaining historical information in this model.

#### 📊 Analytics

-   **mrt_gaps_by_exchange_rate**: In this model, I created all the metrics of interest for sending alerts to Slack. Metrics measuring the gap between all exchange rates and official dollars (retailer and wholesale), MEP, Blue, etc., I created, along with boolean variables to check if the gaps exceeded certain thresholds. Additionally, price variations from the last available value were added to detect abrupt price changes. Metrics to capture arbitrage opportunities were also included.

> 💡 **dbt macros used:** 
>  - `dbt_utils.unpivot`
>  - `dbt_utils.get_column_values`
>  -  `dbt_utils.get_column_values`
>  - `dbt_utils.generate_surrogate_key`
>  - `dbt_utils.safe_divide`

#### 🚨Actions

-   **send_slack_notifications**: I set up a connection to send all the custom alerts we want to monitor. For example, we receive an alert when the gap with the official exchange rate exceeds **45%**, or when there is a price increase greater than **1%** from the last run. Additionally, I receive notifications when there is an arbitrage opportunity for the **USDT/ARS** pair among crypto exchanges. Finally, a summary table of the main rates is sent to the channel.

![slack 1](https://github.com/y42-demo-path/hackathon-09/assets/67651418/13f28933-5d3d-406e-9128-c4c3422d8433)

![slack 2](https://github.com/y42-demo-path/hackathon-09/assets/67651418/b5850752-9bc9-4693-b7a6-a02dc58514cc)


-   **retl_google_sheet**: As I do not have Snowflake credentials, an R-ETL process was created to send data to a Google Sheet, allowing for any additional analytical analysis (charts, pivot tables, etc.). Kudos to **Rob** to help me providing this piece of code.

#### 📑 Quality Testing and Descriptions

I created tests to ensure that IDs are unique and do not contain null values, as well as tests for other important fields. Recency tests were also placed on the main models to verify that the ingested information is the latest available. Additionally, all models and their columns were documented.

#### 🖹 Documentation

-   [Python Sources](https://www.y42.com/docs/python-sources)
-   [BCRA's API](https://www.bcra.gob.ar/BCRAyVos/catalogo-de-APIs-banco-central-i.asp)
-   [Criptoya's API](https://criptoya.com/api)
-   [Yahoo Finance library](https://pypi.org/project/yfinance/)
-   [Differences between MEP and CCL](https://finco.com.ar/productos/dolar-mep-y-ccl/)
-   [Send Slack Notifications](https://www.y42.com/docs/python-actions/send-slack-notifications)
-   [dbt utils](https://github.com/dbt-labs/dbt-utils)
