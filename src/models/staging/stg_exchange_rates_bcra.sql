with source as ( 

    select * from {{ source('raw_bcra_api', 'raw_bcra_api') }}

),

renamed as (
    
    select 

        "idVariable" as variable_id,
        "descripcion" as variable_description,
        "valor" as variable_value,
        "fecha"::date as variable_at

    from source

),

filter_exchange_rates as (

    select *
    from renamed
    where variable_id in (4, 5)
)

select * from filtered 
