
    
with source_data as (
with exp as (select
distinct 
experience
from `dev-env-368414`.`freework`.`jobs_cleaning_aggregation`

)
select 
to_hex(md5(cast(coalesce(cast(experience as string), '_dbt_utils_surrogate_key_null_') as string))) as experience_id,
experience
from exp
)
select * from source_data