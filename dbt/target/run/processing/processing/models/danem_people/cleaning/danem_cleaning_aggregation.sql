
  
    

    create or replace table `dev-env-368414`.`danem_people`.`danem_cleaning_aggregation`
      
    partition by timestamp_trunc(insert_date, day)
    

    OPTIONS()
    as (
      

with aggregated_jobs as (
    select * from `dev-env-368414`.`danem_people`.`danem_cleaning_cdi`
    

    union all 

    select * from `dev-env-368414`.`danem_people`.`danem_cleaning_freelance`
    
) 
select * from aggregated_jobs
    );
  