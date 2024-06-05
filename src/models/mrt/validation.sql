with ref as ( 

    select * from {{ ref('mrt_gaps_by_exchange_rate') }}

)

select *
from ref
where
processed_at in (select max(processed_at) from ref)
and IS_HIGH_CHANGE_TOTAL_BID_PRICE
ORDER BY gap_over_official_wholesale_exchange_rate desc, processed_at
-- processed_at in (select max(processed_at) from ref)
