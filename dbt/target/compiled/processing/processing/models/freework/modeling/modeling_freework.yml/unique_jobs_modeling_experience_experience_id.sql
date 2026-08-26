
    
    

with dbt_test__target as (

  select experience_id as unique_field
  from `dev-env-368414`.`freework`.`jobs_modeling_experience`
  where experience_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


