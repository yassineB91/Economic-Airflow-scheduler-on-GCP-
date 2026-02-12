{{config(
    materialized="incremental",
    unique_key='skill_id')}}

with source_data as (

with technologies as  (
SELECT 
    distinct 
    {{get_skills('skills')}} as skill
    FROM {{ref('jobs_cleaning_aggregation')}},
    unnest(split(key_skills,",")) as skills
    where {{get_skills('skills')}}<>"CDI"
    and {{get_skills('skills')}} <>"Freelance"
    and {{get_skills('skills')}} <>"CDD"
{% if is_incremental() %}
  and insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
 )
 select
    {{dbt_utils.generate_surrogate_key(['skill'])}} as skill_id,
    skill
    from technologies
)
select * from source_data