with unioned_model as ( 

    select * from {{ ref('int_exchange_rates_unioned') }}

)

select * from unioned_model
