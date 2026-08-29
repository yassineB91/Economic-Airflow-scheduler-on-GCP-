

with source_data as (
select distinct j.*,r.job_category from `dev-env-368414`.`freework`.`jobs_modeling_fact_jobs_initial` j
left outer join `dev-env-368414`.`freework`.`jobs_modeling_ref_job_category` r
on j.job_id=r.job_id

)
select * from source_data