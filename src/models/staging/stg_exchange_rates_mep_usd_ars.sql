with source as (
	
	select * 
	from {{ source('raw_criptoya_api', 'raw_exchange_rates_mep_usd_ars') }}

),

renamed AS (

	select
	
		"index" as exchange_rate_name,
		"price" as total_bid_price,
		"timestamp" as updated_at

	from source

),

stage as (

    select

        exchange_rate_name,

        'The MEP dollar arises from the buying and 
			selling of bonds and stocks that are traded in the local and 
			foreign markets.' as indicator_description,  

        'Criptoya - MEP' as source_reference,
        coalesce(total_bid_price, 0) as total_bid_price,

        avg(total_bid_price) over() as avg_total_bid_price,

        convert_timezone(
            'America/Argentina/Buenos_Aires',
            to_timestamp(updated_at::bigint)
        ) as updated_at

    from renamed

)

select * from stage
