with source as ( 

    select * from {{ source('raw_bcra_api', 'raw_exchange_rates_official_usd_ars') }}

),

renamed as (
    
    select 

        "idVariable" as indicator_id,
        "descripcion" as indicator_description,
        "valor" as indicator_value,
        "fecha"::timestamp as updated_at

    from source

),

filter_exchange_rates as (

    select

        case
            when indicator_id = 4 then 'Official Retailer Dollar'
            when indicator_id = 5 then 'Official Wholesale Dollar'
        end as exchange_rate_name,

        indicator_description,
        'BCRA' as source_reference,
        indicator_value as total_bid_price,
        avg(total_bid_price) over() as avg_total_bid_price,
        updated_at
        
    from renamed
    where indicator_id in (4, 5)
    
)

select * from filter_exchange_rates 
