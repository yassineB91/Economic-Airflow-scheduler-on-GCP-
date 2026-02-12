{{ config(
    materialized = 'incremental',
    partition_by = {'field': 'insert_date', 'data_type': 'timestamp'},
    incremental_strategy = 'insert_overwrite'
) }}

with source_data as (
select 
split(title,"-")[0] as job,
"CDI or Freelance" as job_type,
{{get_salary('salary_tjm','max')}} as salary_min,
{{get_salary('salary_tjm','max')}} as salary_max,
{{get_tjm('salary_tjm','min')}} as tjm_min,
{{get_tjm('salary_tjm','max')}} as tjm_max,
 start,
 duration,
 experience,
 remote,
 location,
 key_skills,
 insert_date,
 description
from {{ source('freework','job_list') }}
 where  key_skills like '%Freelance%'and key_skills  like '%CDI%'
{% if is_incremental() %}
  and insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
)

select  
*
from source_data 