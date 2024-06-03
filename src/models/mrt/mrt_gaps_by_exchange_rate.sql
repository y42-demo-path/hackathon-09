{% set gap_over_mep_threshold = 0.05 %}
{% set gap_over_official_threshold = 0.5 %}
{% set change_total_bid_threshold = 0.03 %}
{% set change_gap_over_official_threshold = 0.03 %}
{% set change_gap_over_mep_threshold = 0.03 %}

{% set metrics_threshold  = {

    'total_bid_price': 0.03,
    'gap_over_official_retailer_exchange_rate': 0.03,
    'gap_over_mep_exchange_rate': 0.03

} %}


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
        ) }} - 1 as gap_over_official_wholesale_exchange_rate,
        
        {{ dbt_utils.safe_divide(
            'total_bid_price', 'avg_mep_dollar'
        ) }} - 1 as gap_over_mep_exchange_rate,
        
        gap_over_official_retailer_exchange_rate > {{ gap_over_official_threshold }} 
            as is_high_official_gap,
        gap_over_mep_exchange_rate > {{ gap_over_mep_threshold }} 
            as is_high_mep_gap

        {% for metrics in metrics_threshold %}

            ,lag({{ metrics }}) over(
                partition by exchange_rate_name
                order by processed_at
            ) {{ metrics }}_lagged

        {% endfor %}


    from int_unioned_model
    where source_reference not in ('BCRA')

),

changes as (

    select 
        
        *

        {% for metrics, threshold  in metrics_threshold.items() %}

            ,first_value({{ metrics }}_lagged) over(
                partition by exchange_rate_name
                order by updated_at
            ) as {{ metrics }}_previous_close_day

            ,{{ dbt_utils.safe_divide(
                metrics, 
                metrics ~ '_previous_close_day'
            ) }} - 1 as change_{{ metrics }}_previous_day

            ,change_{{ metrics }}_previous_day > {{ threshold }} 
                as is_high_change_{{ metrics }}

        {% endfor %}


    from gaps

)

select * from changes
