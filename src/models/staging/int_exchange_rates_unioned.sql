{{
  config(
    materialized = 'incremental'
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
        'avg_total_bid_price',
        'avg_total_ask_price',
        'updated_at',
        'current_timestamp'
    ]
%}

{%- set types_bcra_exchange_rates = dbt_utils.get_column_values(
    table=ref('stg_exchange_rates_official_usd_ars'),
    column='exchange_rate_name'
) -%}


with exchange_rates_unioned as (

    {{ dbt_utils.union_relations(
        relations=[
            ref('stg_exchange_rates_official_usd_ars'),
            ref('stg_exchange_rates_other_usd_ars'),
            ref('stg_exchange_rates_cripto_usdt_ars'),
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
        coalesce(total_ask_price, 0) as total_ask_price,
        avg_total_bid_price,
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
                case when exchange_rate_name = '{{ types_bcra_exchange_rate }}' then total_bid_price end
            ignore nulls) over(order by updated_at)
                as {{ dbt_utils.slugify(types_bcra_exchange_rate) }},
            
        {% endfor %}

            last_value(
                case when exchange_rate_name like 'MEP%' then avg_total_bid_price end
            ignore nulls) over(order by updated_at)
                as avg_mep_dollar,

        convert_timezone(
            'America/Argentina/Buenos_Aires',
            current_timestamp
        ) as processed_at

    from fields_coalesced
	
    {% if is_incremental() %}
    
    where processed_at > (select max(processed_at) from {{ this }})
    
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
        avg_total_bid_price,
		avg_total_ask_price,
		official_retailer_dollar,
		official_wholesale_dollar,
		avg_mep_dollar,
		updated_at,
		processed_at

	from transformations

)

select * from final
