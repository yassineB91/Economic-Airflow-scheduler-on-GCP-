
  
    

    create or replace table `dev-env-368414`.`freework`.`compare_queries_location`
      
    
    

    OPTIONS()
    as (
      





with a as (

    

select 
location_id,
location 
from `dev-env-368414`.`freework`.`jobs_modeling_location`


),

b as (

    

select location_id,
location
from `dev-env-368414`.`freework`.`jobs_modeling_location_standardized`


),

a_intersect_b as (

    select * from a
    

    intersect distinct


    select * from b

),

a_except_b as (

    select * from a
    

    except distinct


    select * from b

),

b_except_a as (

    select * from b
    

    except distinct


    select * from a

),

all_records as (

    select
        *,
        true as in_a,
        true as in_b
    from a_intersect_b

    union all

    select
        *,
        true as in_a,
        false as in_b
    from a_except_b

    union all

    select
        *,
        false as in_a,
        true as in_b
    from b_except_a

),

summary_stats as (

    select

        in_a,
        in_b,
        count(*) as count

    from all_records
    group by 1, 2

),

final as (

    select

        *,
        round(100.0 * count / sum(count) over (), 2) as percent_of_total

    from summary_stats
    order by in_a desc, in_b desc

)

select * from final


    );
  