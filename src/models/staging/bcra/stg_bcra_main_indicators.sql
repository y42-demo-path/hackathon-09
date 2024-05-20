with source as ( 

    select * from {{ ref('bcra_main_indicators__snapshot') }} 

),

renamed as (
    
    select 

        idVariable	as variable_id,
        descripcion as variable_description,
        valor as variable_value,
        fecha::timestamp as variable_at

    from source

)

select * from renamed   
