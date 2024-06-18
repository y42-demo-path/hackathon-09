{% set gap_over_mep_threshold = 0.03 %}
{% set gap_over_official_threshold = 0.45 %}
{% set arbitrage_threshold = 0.01 %}

{% set metrics_threshold  = {

    'total_bid_price': 0.01,
    'gap_over_official_wholesale_exchange_rate': 0.015,
    'gap_over_mep_exchange_rate': 0.03

} %}

{% set top_cripto_exchanges = 

    'Buenbit',
    'Ripio',
    'Satoshitango',
    'Decrypto',
    'Letsbit',
    'Binance',
    'Fiwind',
    'Lemon Cash',
    'Belo',
    'Tiendacrypto',
    'Cocos Crypto' 

%}


with int_unioned_model as (

    select * from {{ ref('int_exchange_rates_unioned') }}

),

gaps_metrics as (

    select

        *,

        exchange_rate_name in {{ top_cripto_exchanges }} as is_top_cripto_exchanges,

        exchange_rate_name like '%P2P%' as is_p2p_exchange,

        {{ dbt_utils.safe_divide(
            'total_ask_price', 
            'total_bid_price'
        ) }} - 1 as spread,

        {{ dbt_utils.safe_divide(
            'total_bid_price', 
            'official_retailer_dollar'
        ) }} - 1 as gap_over_official_retailer_exchange_rate,

        {{ dbt_utils.safe_divide('
            total_bid_price', 
            'official_wholesale_dollar'
        ) }} - 1 as gap_over_official_wholesale_exchange_rate,

        {{ dbt_utils.safe_divide(
            'total_bid_price', 'avg_mep_dollar'
        ) }} - 1 as gap_over_mep_exchange_rate,

        max(
            iff(
                source_reference = 'Criptoya - Cripto'
                and is_top_cripto_exchanges,
                total_bid_price, 
                null
            )
        ) over (
            partition by processed_at
        ) as max_total_bid_price,

        min(
            iff(
                source_reference = 'Criptoya - Cripto'
                and is_top_cripto_exchanges,
                total_ask_price,
                null
            )
        ) over (
            partition by processed_at
        ) as min_total_ask_price,

        {{ dbt_utils.safe_divide(
            'max_total_bid_price', 'min_total_ask_price'
        ) }} -1 as arbitrage_ratio,

        arbitrage_ratio > {{ arbitrage_threshold }} as is_arbitrage_opportunity,

        gap_over_official_wholesale_exchange_rate > {{ gap_over_official_threshold }}
            as is_high_official_gap,
        gap_over_mep_exchange_rate > {{ gap_over_mep_threshold }}
            as is_high_mep_gap

        {% for metrics in metrics_threshold %}

            ,lag({{ metrics }}) over (
                partition by exchange_rate_name
                order by processed_at
            ) as {{ metrics }}_lagged

        {% endfor %}


    from int_unioned_model
    where source_reference not in ('BCRA')

),

change_metrics as (

    select

        *

        {% for metrics, threshold  in metrics_threshold.items() %}

            ,{{ dbt_utils.safe_divide(
                metrics, 
                metrics ~ '_lagged'
            ) }} -1 as change_{{ metrics }}

            ,change_{{ metrics }} > {{ threshold }}
                as is_high_change_{{ metrics }}

        {% endfor %}


    from gaps_metrics

),

final as (

    select 

        exchange_rate_token,
        exchange_rate_name,
        indicator_description,
        source_reference,
        bid_price,
        ask_price,
        total_bid_price,
        total_ask_price,
        avg_total_bid_price,
        avg_total_ask_price,
        max_total_bid_price,
        min_total_ask_price,
        official_retailer_dollar,
        official_wholesale_dollar,
        avg_mep_dollar,
        total_bid_price_lagged,
        gap_over_official_retailer_exchange_rate,
        gap_over_official_wholesale_exchange_rate,
        gap_over_mep_exchange_rate,
        gap_over_mep_exchange_rate_lagged,
        gap_over_official_wholesale_exchange_rate_lagged,
        change_total_bid_price,
        change_gap_over_official_wholesale_exchange_rate,
        change_gap_over_mep_exchange_rate,
        spread,
        arbitrage_ratio,
        is_p2p_exchange,
        is_top_cripto_exchanges,
        is_high_mep_gap,
        is_arbitrage_opportunity,
        is_high_official_gap,
        is_high_change_total_bid_price,
        is_high_change_gap_over_official_wholesale_exchange_rate,
        is_high_change_gap_over_mep_exchange_rate,
        updated_at,
        processed_at

    from change_metrics

)

select * from final
