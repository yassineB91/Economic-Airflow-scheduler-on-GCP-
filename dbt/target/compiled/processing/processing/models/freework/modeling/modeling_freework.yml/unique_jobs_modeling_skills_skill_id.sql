
    
    

with dbt_test__target as (

  select skill_id as unique_field
  from `processing-452316`.`freework`.`jobs_modeling_skills`
  where skill_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


