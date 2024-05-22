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

)

select * from renamed 
