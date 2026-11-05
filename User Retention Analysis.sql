SELECT * 
FROM cohort_users_raw 
LIMIT 10; 


 select *
 from cohort_events_raw 
 limit 10;
 
 
 
 with users_parts as (
  select user_id, signup_datetime, promo_signup_flag  , 
 split_part (trim (signup_datetime), ' ', 1), 
 replace(split_part (trim (signup_datetime), ' ', 1) , '.','-'),
 split_part( 
          replace(split_part (trim (signup_datetime), ' ', 1),
          '.','-'),
          '-', 1)
          as day_part,
          split_part( 
          replace(split_part (trim (signup_datetime), ' ', 1),
          '.','-'),
          '-', 2)
          as month_part,
          split_part( 
          replace(split_part (trim (signup_datetime), ' ', 1),
          '.','-'),
          '-', 3)
          as year_part
         from cohort_users_raw
          ),
          users_fixed as(           
          select user_id, promo_signup_flag, day_part, month_part, year_part,
         case 
 	when length(year_part) = 2
 	then '20' || year_part
 	else year_part
 end as fixed_years,
 case 
 	when length(month_part) = 1
 	then '0' || month_part
 	else month_part
 end as fixed_months,
 case 
 	when length(day_part) = 1
 	then '0' || day_part
 	else day_part
 end as fixed_days
 from users_parts
 ),
 users_clean as(
select user_id, promo_signup_flag,
cast(
to_date (fixed_days || '-' || fixed_months ||'-'|| fixed_years 
, 'DD-MM-YYYY') as timestamp
)as signup_timestamp
from users_fixed
),
events_parts as(
 select user_id, event_datetime, event_type,
 split_part (trim (event_datetime), ' ', 1), 
 replace(
 split_part(trim (event_datetime), ' ', 1), 
 '.',
 '-'
 ),
split_part(replace(split_part (trim (event_datetime), ' ', 1),
          '.','-'),
          '-', 1)
          as day_part,
          split_part( 
          replace(split_part (trim (event_datetime), ' ', 1),
          '.','-'),
          '-', 2)
          as month_part,
          split_part( 
          replace(split_part (trim (event_datetime), ' ', 1),
          '.','-'),
          '-', 3)
          as year_part
         from cohort_events_raw
          ),
          events_fixed as(           
          select user_id, event_type, day_part, month_part, year_part,
         case 
 	when length(year_part) = 2
 	then '20' || year_part
 	else year_part
 end as fixed_years
 ,
 case 
 	when length(month_part) = 1
 	then '0' || month_part
 	else month_part
 end as fixed_months,
 case 
 	when length(day_part) = 1
 	then '0' || day_part
 	else day_part
 end as fixed_days
 from events_parts),
 events_clean as(
select user_id, 
event_type, 
cast(
    to_date (fixed_days || '-' || fixed_months ||'-'|| fixed_years 
, 'DD-MM-YYYY') as timestamp
)as event_timestamp
from events_fixed
)
select 
u.promo_signup_flag,
 date_trunc('month',u.signup_timestamp)::date  as cohort_month,
 (
(extract(year from e.event_timestamp)
 -extract(year from u.signup_timestamp)) * 12
 +
 (extract(month from e.event_timestamp)
 -extract(month from u.signup_timestamp))
 )as month_offset,
 count(distinct u.user_id) as users_total
 from users_clean u
 join events_clean e
 on u.user_id = e.user_id
 where u.signup_timestamp is not null
 and e.event_timestamp is not null 
 and e.event_type is not null 
 and e.event_type <> 'test_event'
 and u.signup_timestamp >='2025-01-01'
 and u.signup_timestamp < '2025-07-01'
 and e.event_timestamp >='2025-01-01'
 and e.event_timestamp < '2025-07-01'
 group by u.promo_signup_flag,
 date_trunc('month',u.signup_timestamp)::date,
 (
  (extract(year from e.event_timestamp)
 -extract(year from u.signup_timestamp)) * 12
 +
 (extract(month from e.event_timestamp)
 -extract(month from u.signup_timestamp))
 )
 order by
 u.promo_signup_flag, cohort_month, month_offset;
 
 