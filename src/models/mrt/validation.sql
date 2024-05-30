with int_unioned_model as ( 

    select * from {{ ref('int_exchange_rates_unioned') }}

)

select PROCESSED_AT, count(*)
from int_unioned_model
group by 1
--where SOURCE_REFERENCE='BCRA'
