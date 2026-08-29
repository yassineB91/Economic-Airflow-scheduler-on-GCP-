
    
    

with child as (
    select skill_id as from_field
    from `dev-env-368414`.`freework`.`jobs_modeling_fact_jobs_initial`
    where skill_id is not null
),

parent as (
    select skill_id as to_field
    from `dev-env-368414`.`freework`.`jobs_modeling_skills`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


