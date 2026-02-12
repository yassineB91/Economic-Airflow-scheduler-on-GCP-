
  
    

    create or replace table `processing-452316`.`danem_people`.`danem_cleaning_aggregation`
      
    partition by timestamp_trunc(insert_date, day)
    

    OPTIONS()
    as (
      

with aggregated_jobs as (
    select * from `processing-452316`.`danem_people`.`danem_cleaning_cdi`
    

    union all 

    select * from `processing-452316`.`danem_people`.`danem_cleaning_freelance`
    
) 
select * from aggregated_jobs
    );
  