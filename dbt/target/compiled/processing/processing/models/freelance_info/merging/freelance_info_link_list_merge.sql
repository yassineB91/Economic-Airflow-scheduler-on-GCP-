

with links as 
(select 
title, skills, publish_date,location,start_date, duration, insert_date
from `processing-452316`.`freelance_info`.`list_links_ext`)

select * from links