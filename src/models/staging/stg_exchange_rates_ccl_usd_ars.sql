with source as (

	{{ dbt_utils.unpivot(
		relation=source('raw_yahoofinance_api', 'raw_exchange_rates_ccl_usd_ars'),
		cast_to='varchar',
		exclude=["DATETIME"],
		field_name="exchange_rate_name",
		value_name="total_bid_price"
	) }}

),

renamed as (

	select 

		concat('CCL ', exchange_rate_name) as exchange_rate_name,

        'The CCL dollar arises from the buying and selling of bonds 
			and stocks that are listed both in the local market 
			and abroad.' as indicator_description,
			
		'Yahoo Finance' as source_reference,
		total_bid_price::float as total_bid_price,
		avg(total_bid_price) over() as avg_total_bid_price,
        
        convert_timezone(
            'America/Argentina/Buenos_Aires',
            to_timestamp(substring(datetime, 1, 10))
        ) as updated_at

	from source

)

select * from renamed
