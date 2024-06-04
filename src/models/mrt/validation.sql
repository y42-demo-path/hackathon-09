with int_unioned_model as ( 

    select * from {{ ref('int_exchange_rates_unioned') }}

)

select exchange_rate_name, count(*)
from int_unioned_model
where SOURCE_REFERENCE='Criptoya'
group by 1
order by 1
--
