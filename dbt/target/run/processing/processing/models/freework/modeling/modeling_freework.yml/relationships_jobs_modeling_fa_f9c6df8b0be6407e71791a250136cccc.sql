select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with child as (
    select job_type_id as from_field
    from `processing-452316`.`freework`.`jobs_modeling_fact_jobs_initial`
    where job_type_id is not null
),

parent as (
    select job_type_id as to_field
    from `processing-452316`.`freework`.`jobs_modeling_type`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



      
    ) dbt_internal_test