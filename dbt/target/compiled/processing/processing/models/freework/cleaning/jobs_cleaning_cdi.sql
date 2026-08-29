

with source as (
    select * from `dev-env-368414`.`freework`.`job_list`
),

filtered_jobs as (
    select
        to_hex(md5(cast(coalesce(cast(title as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(insert_date as string), '_dbt_utils_surrogate_key_null_') as string))) as job_id,
        split(title, '-')[OFFSET(0)] as job,
        'CDI' as job_type,
        safe_cast(replace(split(salary_tjm, '-')[OFFSET(0)], 'k', '000') as numeric) as salary_min,
        safe_cast(replace(split(salary_tjm, '-')[SAFE_OFFSET(1)], 'k €/an', '000') as numeric) as salary_max,
        start,
        duration,
        experience,
        remote,
        location,
        key_skills,
        insert_date,
        description
    from source
    where 1=1
        and key_skills not like '%Freelance%'
        and key_skills like '%CDI%'
        and split(title, '-')[OFFSET(0)] != ''
        
)

select distinct *
from filtered_jobs