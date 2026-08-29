
  
    

    create or replace table `dev-env-368414`.`freework`.`freelance_info_link_list_merge`
      
    
    

    OPTIONS()
    as (
      

with links as 
(select 
title, skills, publish_date,location,start_date, duration, insert_date
from `dev-env-368414`.`freelance_info`.`list_links_ext`)

select * from links
    );
  