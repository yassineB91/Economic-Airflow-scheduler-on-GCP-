

with location_table as (
  select distinct location_id, location, split(location,",")[0] as loc
 from `dev-env-368414`.`freework`.`jobs_modeling_location`),
  source_data as (
 select distinct location_id,location, loc
  from location_table 
 where location not like "%<%" and location not like "%Télétravail%" and location not like "")

 select * from source_data