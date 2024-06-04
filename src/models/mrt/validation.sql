with ref as ( 

    select * from {{ ref('mrt_gaps_by_exchange_rate') }}

)

select *
from ref
where 
is_high_official_gap
and processed_at in (select max(processed_at) from ref)
