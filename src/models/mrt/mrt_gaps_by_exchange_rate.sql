{% set gap_over_mep_threshold = 0.05 %}
{% set gap_over_official_threshold = 0.4 %}

{% set metrics_threshold  = {

    'total_bid_price': 0.03,
    'gap_over_official_retailer_exchange_rate': 0.03,
    'gap_over_mep_exchange_rate': 0.03

} %}

{% set top_cripto_exchanges = 

    'Buenbit',
    'Ripio',
    'Satoshitango',
    'Decrypto',
    'Letsbit',
    'Binance P2P',
    'Fiwind',
    'Lemon Cash',
    'Belo',
    'Tiendacrypto',
    'Cocos Crypto' 

%}




with int_unioned_model as (

    select * from {{ ref('int_exchange_rates_unioned') }}

),

gaps as (

    select

        *,

        {{ dbt_utils.safe_divide(
            'total_bid_price', 
            'official_retailer_dollar'
        ) }} -1 as gap_over_official_retailer_exchange_rate,

        {{ dbt_utils.safe_divide('
            total_bid_price', 
            'official_wholesale_dollar'
        ) }} -1 as gap_over_official_wholesale_exchange_rate,

        {{ dbt_utils.safe_divide(
            'total_bid_price', 'avg_mep_dollar'
        ) }} -1 as gap_over_mep_exchange_rate,

        max(
            iff(
                source_reference = 'Criptoya - Cripto'
                and exchange_rate_name in {{ top_cripto_exchanges }},
                total_bid_price, 
                null
            )
        ) over (
            partition by processed_at
        ) as max_total_bid_price,

        min(
            iff(
                source_reference = 'Criptoya - Cripto'
                and exchange_rate_name in {{ top_cripto_exchanges }},
                total_ask_price,
                null
            )
        ) over (
            partition by processed_at
        ) as min_total_ask_price,

        max_total_bid_price > min_total_ask_price as is_arbitrage_opportunity,

        {{ dbt_utils.safe_divide(
            'max_total_bid_price', 'min_total_ask_price'
        ) }} -1 as arbitrage_ratio,

        gap_over_official_retailer_exchange_rate > {{ gap_over_official_threshold }}
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

changes as (

    select

        *

        {% for metrics, threshold  in metrics_threshold.items() %}

            ,first_value({{ metrics }}_lagged) over (
                partition by exchange_rate_name
                order by updated_at
            ) as {{ metrics }}_previous_close_day

            ,{{ dbt_utils.safe_divide(
                metrics, 
                metrics ~ '_previous_close_day'
            ) }} -1 as change_{{ metrics }}_previous_day

            ,change_{{ metrics }}_previous_day > {{ threshold }}
                as is_high_change_{{ metrics }}

        {% endfor %}


    from gaps

)

select * from changes
