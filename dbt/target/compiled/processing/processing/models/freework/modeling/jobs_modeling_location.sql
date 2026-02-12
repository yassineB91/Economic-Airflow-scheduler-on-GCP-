

with source_data as (
with exp as (select
distinct 
location
from `processing-452316`.`freework`.`jobs_cleaning_aggregation`

)
select 
to_hex(md5(cast(coalesce(cast(location as string), '_dbt_utils_surrogate_key_null_') as string))) as location_id,
location
from exp)
select * from source_data