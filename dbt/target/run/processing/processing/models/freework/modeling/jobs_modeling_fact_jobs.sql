
  
    

    create or replace table `processing-452316`.`freework`.`jobs_modeling_fact_jobs`
      
    
    

    OPTIONS()
    as (
      

with source_data as (
select distinct j.*,r.job_category from `processing-452316`.`freework`.`jobs_modeling_fact_jobs_initial` j
left outer join `processing-452316`.`freework`.`jobs_modeling_ref_job_category` r
on j.job_id=r.job_id

)
select * from source_data
    );
  