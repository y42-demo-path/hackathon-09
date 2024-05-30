{% set dollars_descriptions = {

    'ahorro': ['Saving Dollar', 'Exchange rate at which Argentine citizens can buy a limited amount of US dollars for personal savings.'],
    'tarjeta': ['Tourist Dollar', 'Exchange rate used for credit card purchases in foreign currency.'],
    'blue': ['Black Market Dollar', 'Parallel market for buying and selling US dollars in Argentina, also known as the "informal dollar" or "black market dollar".']

} %}


with source as (
	
	select * 
	from {{ source('raw_criptoya_api', 'raw_exchange_rates_other_usd_ars') }}
),

renamed as (

	select
		
		"index" as exchange_rate_name,
		"price" as price,
		"bid" as total_bid_price,
		"ask" as total_ask_price,
		"timestamp" as updated_at

	from source

),

stage as (

    select

        case
            {% for spanish_name, english_name in dollars_descriptions.items() %}
                when exchange_rate_name = '{{ spanish_name }}' then '{{ english_name[0] }}'
            {% endfor %}
            else exchange_rate_name
        end as exchange_rate_name,

        case
            {% for exchange_rate_name, exchange_rate_description in dollars_descriptions.items() %}
                when exchange_rate_name = '{{ exchange_rate_name }}' then '{{ exchange_rate_description[1] }}'
            {% endfor %}
            else exchange_rate_name
        end as indicator_description,    

        'Criptoya' as source_reference,
        coalesce(total_bid_price, price, 0) as total_bid_price,
        coalesce(total_ask_price, price, 0) as total_ask_price,
        avg(total_bid_price) over() as avg_total_bid_price,
        avg(total_ask_price) over() as avg_total_ask_price,

        convert_timezone(
            'America/Argentina/Buenos_Aires',
            to_timestamp(updated_at::bigint)
        ) as updated_at

    from renamed

)

select * from stage
