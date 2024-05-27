{% set columns_to_tokenize =
    [
        'exchange_name', 
        'indicator_description',
        'source_reference',
        'bid_price',
        'total_bid_price',
        'ask_price',
        'total_ask_price',
        'avg_total_ask_price',
        'indicator_at'
    ]
%}


with exchange_rates_unioned as (

    {{ dbt_utils.union_relations(
        relations=[
            ref('stg_exchange_rates_bcra'),
            ref('stg_exchange_rates_usdt_ars')
        ]
    ) }}
),

fields_coalesced as (

    select

        exchange_name,
        indicator_description,
        source_reference,
        coalesce(bid_price, 0) as bid_price,
        coalesce(total_bid_price, 0) as total_bid_price,
        coalesce(ask_price, 0) as ask_price,
        total_ask_price,
        avg_total_ask_price,
        indicator_at      

    from exchange_rates_unioned

),

final as (

    select 

        {{ dbt_utils.generate_surrogate_key(columns_to_tokenize) }} as exchange_rates_token,
        
        *,

        current_timestamp as ingested_at  

    from exchange_rates_coalesced

)

select * from final
