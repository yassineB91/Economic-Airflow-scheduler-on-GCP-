{{config(
  materialized='incremental',
  unique_key = 'link',
  merge_exclude_columns  = ['insert_date']

)}}

with links as 
(select 
link, insert_date
from {{source('danem_people','list_links_ext')}})

select * from links