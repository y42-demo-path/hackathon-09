with source as (

    select *
    from {{ source('raw_criptoya_api', 'raw_exchange_rates_cripto_usdt_ars') }}

),

renamed as (

    select

        "index" as exchange_rate_name,
        "bid" as bid_price,
        "totalBid" as total_bid_price,
        "ask" as ask_price,
        "totalAsk" as total_ask_price,
        "time" as updated_at

    from source

),

stage as (

    select

        {{ map_values_from_seed('exchange_rate_name','exchange_names_mapping') }} as exchange_rate_name,
        'Cripto Exchange Rate (USDT / ARS)'  as indicator_description,
        'Criptoya - Cripto' as source_reference,
        bid_price,
        total_bid_price,
        ask_price,
        total_ask_price,

        avg(total_bid_price) over() as avg_total_bid_price,

        avg(total_ask_price) over() as avg_total_ask_price,

        convert_timezone(
            'America/Argentina/Buenos_Aires',
            to_timestamp(updated_at::bigint)
        ) as updated_at

    from renamed

)

select * from stage
