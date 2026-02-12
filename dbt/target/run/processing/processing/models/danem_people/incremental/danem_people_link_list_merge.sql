
  
    

    create or replace table `processing-452316`.`danem_people`.`danem_people_link_list_merge`
      
    
    

    OPTIONS()
    as (
      

with links as 
(select 
link, insert_date
from `processing-452316`.`danem_people`.`list_links_ext`)

select * from links
    );
  