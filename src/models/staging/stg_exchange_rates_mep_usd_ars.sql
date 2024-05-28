WITH source AS (
	
	SELECT * 
	FROM {{ source('raw_criptoya_api', 'raw_exchange_rates_mep_usd_ars') }}

),

renamed AS (

	SELECT
	
		"index" as exchange_rate_name,
		"price" as total_ask_price,
		"timestamp" as updated_at

	FROM source

),

stage as (

    select

        exchange_rate_name,

        'The MEP dollar (or stock market dollar) arises from the buying and 
			selling of bonds and stocks that are traded in the local and 
			foreign markets.' as indicator_description,  

        'Criptoya' as source_reference,
        coalesce(total_ask_price, 0) as total_ask_price,

        avg(total_ask_price) over() as avg_total_ask_price,

        convert_timezone(
            'America/Argentina/Buenos_Aires',
            to_timestamp(updated_at::bigint)
        ) as updated_at

    from renamed

)

select * from stage
