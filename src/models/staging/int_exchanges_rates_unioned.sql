with stg_exchange_rates_bcra as ( 

    select * from {{ ref('stg_exchange_rates_bcra') }}

),

stg_exchange_rates_usdt_ars as ( 

    select * from {{ ref('stg_exchange_rates_usdt_ars') }}

),

exchange_rates_unioned as (


    select *
    from stg_exchange_rates_bcra

    union all

    select *
    from stg_exchange_rates_usdt_ars

),

exchange_rates_add_timestamp as (

    select 
        
        *,
        {{dbt.current_timestamp}} as current_timestamp

    from exchange_rates_unioned

)

select * from exchange_rates_add_timestamp
