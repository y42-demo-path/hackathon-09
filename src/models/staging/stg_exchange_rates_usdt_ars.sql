with source as (

    select *
    from {{ source('raw_criptoya_usdt_ars', 'raw_criptoya_usdt_ars') }}

),

renamed as (

    select

        "index" as exchange_name,
        "bid" as bid_price,
        "totalBid" as total_bid_price,
        "ask" as ask_price,
        "totalAsk" as total_ask_price,
        "time" as update_at

    from source

),

stg as (

    select

        exchange_name,
        bid_price,
        total_bid_price,
        ask_price,
        total_ask_price,

        avg(total_ask_price) over() as avg_total_ask_price,

        convert_timezone(
            'America/Argentina/Buenos_Aires',
            to_timestamp(update_at::bigint)
        ) as updated_at

    from renamed

)

select * from stg
