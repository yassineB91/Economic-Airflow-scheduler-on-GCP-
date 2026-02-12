{{ config(
    materialized = 'incremental',
    unique_key = 'job',
    partition_by = {
        'field': 'insert_date',
        'data_type': 'timestamp'
    },
    incremental_strategy = 'insert_overwrite'
) }}

with source as (
    select * from {{ source('freework', 'job_list') }}
),

filtered_jobs as (
    select
        {{ dbt_utils.generate_surrogate_key(['title', 'insert_date']) }} as job_id,
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
        {% if is_incremental() %}
            and insert_date > (select max(insert_date) from {{ this }})
        {% endif %}
)

select distinct *
from filtered_jobs