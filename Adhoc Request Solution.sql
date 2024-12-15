here is the SQl Question according to the Question( business Request -1) use the database and give me the SQl Queries

business Request -1 : City-level Fare and Trip Summary Report

Generate a report that display the total trips, average fare per KM, average fare per trip, and the percentage contribution of each city's to the overall trips. This report will help in assessing trip volume, pricing efficiency, and each city's contribution to the overall trip count.

Fields:
- city_name
- total_trips
- avg_fare_per_km
- avg_fare_per_trip
- %_contribution_to_total_trips

Solution

select 
city_name,
count(trip_id) as total_trips,
round(sum(fare_amount) / sum(distance_travelled_km),2) as avg_fare_per_km,
round(avg(fare_amount),2) as avg_fare_per_trip,
round((count(trip_id)*100) / (select count(trip_id) from fact_trips ),2) as pct_contribution_to_total_trip
from fact_trips
join dim_city 
using(city_id)
group by city_name
order by total_trips desc


Business Request -2: Monthly City-Level Trips Target Performance Report

Generate a report that evaluates the target performance for trips at the monthly and city level. For each city and month, compare the actual trips with the target trips and categories the performance as follows:

- If actual trips are greater than target trips, marks it as "Above Target."
- If actual trips are less than or equal to target trips, marks it as "Below Target."

Additionally, Calculate the % difference between actual and target trips to quantify the performance Gap 

fields:
- City_name
- month_name
- actual_trips
- target_trips
- performance_status
- %_difference


Solution

SELECT  city_name,
month_name,
count(trip_id) as actual_total_trips,
total_target_trips as target_trip,
case 
when count(trip_id) > mtt.total_target_trips then "Above Target"
else "Below Target"
end as perfromance_status,
round(((count(trip_id)-total_target_trips)*100)/total_target_trips, 2) as pct_difference
FROM fact_trips ft
join dim_city dc
on ft.city_id = dc.city_id
join dim_date dd
on dd.date = ft.date 
join targets_db.monthly_target_trips mtt
on  ft.city_id = mtt.city_id and dd.start_of_month = mtt.month
group by city_name, month_name, target_trip



Business Request -3: City-Level Repeat Passenger Trip Frequency Report

Generate a report that shows the percentage distribution of repeat passengers by the number of trips they have taken in each city. Calculate the percentage of repeat passengers who took 2 trips, 3 trips, and so on, upto 10 trips.

Each column should represent a trip count category, displaying the percentage passengers who fall into that category out of the total repeat passengers for that city.

This report will help identify cities with high repeat trip frequency, which can indicate strong customer loyalty or frequent usage patterns.

Fields:
-city_name
 2-Trips
 3-Trips
 4-Trips
 5-Trips
 6-Trips
 7-Trips
 8-Trips
 9-Trips
 10-Trips

solution

select 
city_name,
round(sum(case when trip_count = '2-Trips' then repeat_passenger_count end)*100 / sum(repeat_passenger_count),2)  as '2-Trips',
round(sum(case when trip_count = '3-Trips' then repeat_passenger_count end)*100 / sum(repeat_passenger_count),2)  as '3-Trips',
round(sum(case when trip_count = '4-Trips' then repeat_passenger_count end)*100 / sum(repeat_passenger_count),2)  as '4-Trips',
round(sum(case when trip_count = '5-Trips' then repeat_passenger_count end)*100 / sum(repeat_passenger_count),2)  as '5-Trips',
round(sum(case when trip_count = '6-Trips' then repeat_passenger_count end)*100 / sum(repeat_passenger_count),2)  as '6-Trips',
round(sum(case when trip_count = '7-Trips' then repeat_passenger_count end)*100 / sum(repeat_passenger_count),2)  as '7-Trips',
round(sum(case when trip_count = '8-Trips' then repeat_passenger_count end)*100 / sum(repeat_passenger_count),2)  as '8-Trips',
round(sum(case when trip_count = '9-Trips' then repeat_passenger_count end)*100 / sum(repeat_passenger_count),2)  as '9-Trips',
round(sum(case when trip_count = '10-Trips' then repeat_passenger_count end)*100 / sum(repeat_passenger_count),2)  as '10-Trips'

from dim_repeat_trip_distribution
join dim_city
using(city_id)
group by city_name



Business Request -4: Identify Cities with Highest and Lowest Total New Passengers

Generate a report that calculates the total new passengers for each city and ranks them based on this value. Identify the top 3 cities with the highest number of new passengers as well as the bottom 3 cities with lowest number of new passengers, Categorising them as "Top 3" or "Bottom 3" accordingly.

Fields
- city_name
- total_new_passengers
- city_category ("Top 3" or"Bottom 3")

Solution

with x as (select 
city_name, 
sum(new_passengers) as total_new_passengers,
rank() over(order by sum(new_passengers) desc)  as highest_rank,
rank() over(order by sum(new_passengers)) as lowest_rank 
from fact_passenger_summary
join dim_city
using(city_id)
group by city_name),
y as (
select 
city_name,
total_new_passengers,
case when highest_rank <= 3 then "Top 3"
when lowest_rank <= 3 then "Bottom 3"
end as City_Category
from x

)
select * from y
where City_Category is not null
order by  total_new_passengers desc

Business Request -5: Identify Month with Revenue for Each City

Generate a report that identifies the month with highest revenue for each city. For each city, display the month_name, the revenue amount for that month, and the percentage contribution of that month's revenue to the City's total revenue.

Fields
- City_name
- highest_revenue_month
- revenue
- percentage_contribution (%)

solution

with x as (select 
city_name,
month_name, 
sum(fare_amount) as revenue
from fact_trips ft
join dim_date dd
using(date)
join dim_city
using(city_id)
group by city_id, month_name),
y as (select
city_name,
sum(revenue) as total_revenue
from x
group by city_name
),
z as (
select
city_name,
month_name,
revenue,
round((revenue*100)/total_revenue,2) as percentage_contribution
from x qq 
join y 
using(city_name)
where revenue = (select max(revenue) from x sub where sub.city_name = qq.city_name) 
group by city_name, month_name,revenue,percentage_contribution
)
select * from z;


Business Request -6: Repeat Passenger Rate Analysis

Generate a report that calculates two metrics:

1. Monthly Repeat Passenger Rate: Calculate the Repeat passenger rate for each city and month by comparing the number of repeat passengers to the total passengers.
2. City-wide Repeat Passenger Rate: Calculate the overall repeat passenger rate for each city, considering all passengers across months.

These metrics will provides insights into monthly repeat trends as well as overall repeat behaviour each city.

Fields:

- city_name
- month
- total_passengers
- repeat_passengers
- monthly_repeat_passengers_rate(%): Repeat passsengerse rate at the city and month level
- city_repeat_passenger_rate(%): Overall repeat passenger rate for each city, aggregated across months

Solution 

with x as (select 
city_id,
city_name,
month,
total_passengers,
repeat_passengers,
round((repeat_passengers*100)/total_passengers,2) as monthly_repeat_passenger_rate
from fact_passenger_summary
join dim_city
using(city_id)),
 y as (
select 
city_id,
round((sum(repeat_passengers)*100)/sum(total_passengers),2) as city_repeat_passenger_rate
from fact_passenger_summary
group by city_id
)
select 
city_name,
monthname(month) as month,
total_passengers,
repeat_passengers,
monthly_repeat_passenger_rate,
city_repeat_passenger_rate
from x
join y using(city_id)