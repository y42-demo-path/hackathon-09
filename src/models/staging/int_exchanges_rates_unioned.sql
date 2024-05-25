with exchange_rates_unioned as (

    {{ dbt_utils.union_relations(
        relations=[
            ref('stg_exchange_rates_bcra'),
            ref('stg_exchange_rates_usdt_ars')
        ]
    ) }}
),

final as (

    select

        exchange_name,
        indicator_description,
        source_model_reference,
        source_reference,
        coalesce(bid_price, 0) as bid_price,
        coalesce(total_bid_price, 0) as total_bid_price,
        coalesce(ask_price, 0) as ask_price,
        total_ask_price,
        avg_total_ask_price,
        indicator_at,
        current_timestamp as ingested_at        

    from exchange_rates_unioned

)

select * from final
