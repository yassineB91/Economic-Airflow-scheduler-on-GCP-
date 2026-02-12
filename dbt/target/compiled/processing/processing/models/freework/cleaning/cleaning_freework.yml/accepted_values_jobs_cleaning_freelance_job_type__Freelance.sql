
    
    

with all_values as (

    select
        job_type as value_field,
        count(*) as n_records

    from `processing-452316`.`freework`.`jobs_cleaning_freelance`
    group by job_type

)

select *
from all_values
where value_field not in (
    'Freelance'
)


