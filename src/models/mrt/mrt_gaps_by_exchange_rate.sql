{% set gap_over_mep_threshold = 0.05 %}


with int_unioned_model as ( 

    select * from {{ ref('int_exchange_rates_unioned') }}

),

gaps as (

    select 

        *,

        {{ dbt_utils.safe_divide('total_bid_price', 'official_retailer_dollar') }} -1 as gap_over_official_retailer_exchange_rate,
        {{ dbt_utils.safe_divide('total_bid_price', 'official_wholesale_dollar') }} - 1 as gap_over_official_wholesale_exchange_rate,
        {{ dbt_utils.safe_divide('total_bid_price', 'avg_mep_dollar') }} - 1 as gap_over_mep_exchange_rate,
        
        gap_over_mep_exchange_rate > {{ gap_over_mep_threshold }} as is_high_mep_gap,

        lag(total_bid_price) over(
            partition by exchange_rate_name
            order by processed_at
        ) total_bid_price_lagged,

        lag(gap_over_mep_exchange_rate) over(
            partition by exchange_rate_name
            order by processed_at
        ) gap_over_mep_exchange_rate_lagged,


    from int_unioned_model
    where source_reference not in ('BCRA')

),

final as (

    select 
        
        *,

        first_value(total_bid_price_lagged) over(
            partition by exchange_rate_name
            order by updated_at
        ) as total_bid_price_previous_close_day,

        first_value(gap_over_mep_exchange_rate_lagged) over(
            partition by exchange_rate_name
            order by updated_at
        ) as gap_over_mep_exchange_rate_previous_close_day,


        {{ dbt_utils.safe_divide(
            'total_bid_price', 'total_bid_price_previous_close_day'
        ) }} - 1 as change_total_bid_price_previous_day,

        {{ dbt_utils.safe_divide(
            'gap_over_mep_exchange_rate', 'gap_over_mep_exchange_rate_previous_close_day'
        ) }} - 1 as change_gap_over_mep_previous_day 


    from gaps

)

select * from final
