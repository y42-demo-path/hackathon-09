with ref as ( 

    select * from {{ ref('mrt_gaps_by_exchange_rate') }}

)

select *
from ref
where
EXCHANGE_RATE_NAME = 'Binance P2P' 
--processed_at in (select max(processed_at) from ref)
