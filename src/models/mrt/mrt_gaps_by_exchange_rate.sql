with int_unioned_model as ( 

    select * from {{ ref('int_exchange_rates_unioned') }}

),

gaps as (

    select 

        *,

        {{ dbt_utils.safe_divide('total_bid_price', 'official_retailer_dollar') }} -1 as gap_over_official_retailer_exchange_rate,
        {{ dbt_utils.safe_divide('total_bid_price', 'official_wholesale_dollar') }} - 1 as gap_over_official_wholesale_exchange_rate,
        {{ dbt_utils.safe_divide('total_bid_price', 'avg_mep_dollar') }} -1 as gap_over_mep_exchange_rate,

    from int_unioned_model
    where source_reference not in ('BCRA')

)

select * from gaps
