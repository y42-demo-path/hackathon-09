with ref as ( 

    select * from {{ ref('mrt_gaps_by_exchange_rate') }}

)

select 
    EXCHANGE_RATE_NAME, 
    TOTAL_BID_PRICE,  
    round(CHANGE_TOTAL_BID_PRICE * 100, 2) as CHANGE_TOTAL_BID_PRICE
from ref
where
(IS_TOP_CRIPTO_EXCHANGES or SOURCE_REFERENCE not in ('Criptoya - Cripto'))
and
processed_at in (select max(processed_at) from ref)
ORDER BY SOURCE_REFERENCE
