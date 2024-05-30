with int_unioned_model as ( 

    select * from {{ ref('int_exchange_rates_unioned') }}

)

select *
from int_unioned_model
where SOURCE_REFERENCE='BCRA'
