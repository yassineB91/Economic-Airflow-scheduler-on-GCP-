{{config(
  materialized='incremental',
  unique_key = 'title',
  merge_exclude_columns  = ['insert_date']

)}}

with links as 
(select 
title, skills, publish_date,location,start_date, duration, insert_date
from {{source('freelance_info','list_links_ext')}})

select * from links