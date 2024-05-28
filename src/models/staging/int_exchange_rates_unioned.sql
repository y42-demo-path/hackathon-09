{{
  config(
    materialized = 'incremental',
    full_refresh = False,
    unique_key = ['exchange_rate_token']
  )
}}

{% set columns_to_tokenize =
    [
        'exchange_rate_name', 
        'indicator_description',
        'source_reference',
        'bid_price',
        'total_bid_price',
        'ask_price',
        'total_ask_price',
        'avg_total_ask_price',
        'updated_at'
    ]
%}

{%- set types_bcra_exchange_rates = dbt_utils.get_column_values(
    table=ref('stg_exchange_rates_bcra'),
    column='exchange_rate_name'
) -%}


with exchange_rates_unioned as (

    {{ dbt_utils.union_relations(
        relations=[
            ref('stg_exchange_rates_bcra'),
            ref('stg_exchange_rates_usd_ars'),
            ref('stg_exchange_rates_usdt_ars'),
			ref('stg_exchange_rates_mep_usd_ars'),
			ref('stg_exchange_rates_ccl_usd_ars')
        ]
    ) }}

),

fields_coalesced as (

    select

        exchange_rate_name,
        indicator_description,
        source_reference,
        coalesce(bid_price, 0) as bid_price,
        coalesce(total_bid_price, 0) as total_bid_price,
        coalesce(ask_price, 0) as ask_price,
        total_ask_price,
        avg_total_ask_price,
        updated_at      

    from exchange_rates_unioned

),

transformations as (

    select 

        {{ dbt_utils.generate_surrogate_key(columns_to_tokenize) }} as exchange_rate_token,

        *,

        {%- for types_bcra_exchange_rate in types_bcra_exchange_rates %}
        
            last_value(
                case when exchange_rate_name = '{{ types_bcra_exchange_rate }}' then total_ask_price end
            ignore nulls) over(order by updated_at)
                as {{ dbt_utils.slugify(types_bcra_exchange_rate) }},
            
        {% endfor %}

            last_value(
                case when exchange_rate_name like 'MEP%' then avg_total_ask_price end
            ignore nulls) over(order by updated_at)
                as avg_mep_rate,

        current_timestamp as processed_at  

    from fields_coalesced
	
    {% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}

),

final as (

	select 

		exchange_rate_token,
		exchange_rate_name,
		indicator_description,
		source_reference,
		bid_price,
		totaL_bid_price,
		ask_price,
		total_ask_price,
		avg_total_ask_price,
		official_retailer_dollar,
		official_wholesale_dollar,
		avg_mep_rate,
		updated_at,
		processed_at

	from transformations

)

select * from final
