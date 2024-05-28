with source as (

	{{ dbt_utils.unpivot(
		relation=source('raw_yahoofinance_api', 'raw_ccl_usd_ars'),
		exclude=["DATETIME"],
		field_name="exchange_name",
		value_name="total_ask_price"
	) }}

),

renamed as (

	select 

		exchange_rate_name,
        'Exchange rate arises from the buying and selling of bonds 
			and stocks that are listed both in the local market 
			and abroad.' as indicator_description,
		'Yahoo Finance' as source_reference,
		total_ask_price::float as total_ask_price,
		avg(total_ask_price) over() as avg_total_ask_price,
        
        convert_timezone(
            'America/Argentina/Buenos_Aires',
            to_timestamp(substring(datetime, 1, 10))
        ) as updated_at

	from source

)

select * from renamed
