{% set dollars_rename = {

    'ahorro': 'Saving Dollar',
    'tarjeta': 'Tourist Dollar',
    'blue': 'Black Market Dollar'

} %}


with source as (
	
	select * 
	from {{ source('raw_criptoya_api', 'raw_exchange_rates_usd_ars') }}
),

renamed as (

	select
		
		"index" as exchange_name,
		"price" as price,
		"bid" as total_bid_price,
		"ask" as total_ask_price,
		"timestamp" as updated_at

	from source

),

stage as (

    select

        case
            {% for segment_name, condition in dollars_rename.items() %}
                when exchange_name = {{ condition }} then '{{ segment_name }}'
            {% endfor %}
            else retailer_segment
        end as exchange_name
        
		case
            when exchange_name = 'ahorro' then 'Exchange rate at which Argentine citizens can buy a limited amount of US dollars for personal savings.'
            when exchange_name = 'tarjeta' then 'Exchange rate used for credit card purchases in foreign currency.'
            when exchange_name = 'blue' then 'Parallel market for buying and selling US dollars in Argentina, also known as the "informal dollar" or "black market dollar".'			
        end as indicator_description,

        'Criptoya' as source_reference,
        coalesce(total_bid_price, 0) as total_bid_price,
        coalesce(total_ask_price, price, 0) as total_ask_price,

        avg(total_ask_price) over() as avg_total_ask_price,

        convert_timezone(
            'America/Argentina/Buenos_Aires',
            to_timestamp(updated_at::bigint)
        ) as updated_at

    from renamed

)

select * from stage
