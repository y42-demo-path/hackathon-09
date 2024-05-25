with exchange_rates_unioned as (

    {{ dbt_utils.union_relations(
        relations=[
            ref('stg_exchange_rates_bcra'),
            ref('stg_exchange_rates_usdt_ars')
        ],
            source_column_name='source_model_reference'
    ) }}
),

final as (

    select

        exchange_name

    from exchange_rates_unioned

)

select * from final
