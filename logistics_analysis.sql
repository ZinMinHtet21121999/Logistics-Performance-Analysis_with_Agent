-- Which region generates the most revenue?
SELECT region ,
		count(order_id) as total_orders,sum(revenue) as total_revenue,
        round(avg(revenue),2) as average_revenue 
From ecommerce_orders
GROUP by region
order by total_revenue desc;

--- Delivery Status 
with total_orders as (
  SELECT count(*) as total_count
  From ecommerce_orders) 
SELECT status, COUNT(*) as total,
		round(100.0 * COUNT(*) / (SELECT total_count from total_orders),2) as percent_orders
From ecommerce_orders
GROUP by status; 

--- How does revenue change month by month? 
SELECT strftime('%Y-%m',order_date) as month,
		count(*) as total_orders,
		sum(revenue) as total_revenue,
        sum(shipping_cost) as total_shipping_cost
From ecommerce_orders
GROUP by month; 

-- Which agents deliver the most with the best ratings? 

SELECT a.agent_name, a.region,a.vehicle_type,a.rating,
		count(order_id) as total_deliveries,
        round(avg(o.delivery_days),1) as average_delivery_days
FROM delivery_agents a
Join ecommerce_orders o 
On a.agent_id = o.agent_id
GROUP by a.agent_name
order by total_deliveries desc;

--- Which agents have the highest cancelleld delivery rate?
with agent_cancelled_status as(
SELECT a.agent_name ,a.experience_years,
		count(o.order_id) as total_deliveries,
        count (case when o.status = 'Cancelled' then 1 end) as Cancelled_Orders 
From delivery_agents a
join ecommerce_orders o
 On o.agent_id = a.agent_id
 GROUP by a.agent_name
 )
 SELECT * , round(100.0 * Cancelled_Orders/total_deliveries,2)  as cancelled_pct
 From agent_cancelled_status
 GROUP by agent_name 
 order by cancelled_pct desc
 ;
 
 -- Which vehicle type delivers faster and earns more? 
 SELECT vehicle_type,
 		count(*)as total_orders,
        round(avg(delivery_days),2) as average_delivery_days,
        round(avg(revenue),2) as average_revenue,
        round(avg(shipping_cost),2) as average_shipping_cost
 from ecommerce_orders
 GROUP by vehicle_type
 order by average_delivery_days desc ;
 
 -- Cities that contribute above-average revenue 
 with cities_revenue as (
 SELECT city ,
 		sum(revenue) as total_revenue
 From ecommerce_orders
 GROUP by city ) , 
 ranked as ( SELECT *, rank() over(order by total_revenue desc) as rnk From cities_revenue) 
 
 SELECT * 
 from ranked 
 where rnk = 1; 
 
 -- Rank agnets within each region by completed delivers 
 with completed_deliveries as(
 SELECT a.agent_name, a.region,count(o.order_id) as total_deliveries 
 From ecommerce_orders o 
 join delivery_agents a 
 On o.agent_id = a.agent_id
 where status = 'Completed'
 GROUP by a.agent_name )
 SELECT * , 
 		rank() over(partition by region order by total_deliveries desc ) as agent_rnk
        From completed_deliveries ;
        
-- Calculate revenue growth compared to previous month 
with monthly as (
SELECT strftime('%Y-%m',order_date) as month,
		sum(revenue) as total_revenue 
        from ecommerce_orders
        GROUP by month
        )
  SELECT *, lag(total_revenue) over(order by month) as prev_month
  From monthly;
  
-- Do experienced agents perform better? 
with agent_stats as (
  	SELECT a.agent_id,
           a.agent_name,
  		   a.region,
  		   a.experience_years,
  		   a.rating,
  		   count(o.order_id) as total_orders,
           round(avg(o.delivery_days),2) as avg_days 
  		   ,sum (case when status = 'Completed' then 1 else 0 end) as completed_orders
  	From delivery_agents a
  	join ecommerce_orders o 
  	on o.agent_id = a.agent_id 
  	GROUP by a.agent_id) 
    SELECT *, case 
    	when experience_years >= 5 then 'Senior'
    	WHEn experience_years >= 2 then 'Mid'	
        else 'Junior'
       end as experience_level 
     From agent_stats
     order by experience_level desc