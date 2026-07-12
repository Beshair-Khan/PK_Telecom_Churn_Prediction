--Total revenue by operator (prepaid recharges + postpaid payments combined)
select a.operator, sum(a.revenue) as Total_Revenue,
row_number() over(order by sum(a.revenue) desc) as Operator_rank
from (
	select c.operator, i.amount_paid as revenue
	from customers c
	join invoices i 
	on c.customer_id=i.customer_id
	union all
	select c.operator,r.amount_pkr as revenue
	from customers c
	join recharges r
	on c.customer_id =r.customer_id 
	where r.amount_pkr>0) a   --Excludes negative recharge amounts
group by a.operator;

-- Monthly revenue trend per operator with month-over-month growth rate
with revenue as (
	select c.operator, i.amount_paid as revenue, to_char(i.payment_date, 'yyyy-mm') as month
	from customers c
	join invoices i
	on c.customer_id =i.customer_id 
	where i.payment_date is not null
	union all
	select c.operator, r.amount_pkr as revenue, to_char(r.recharge_date,'yyyy-mm') as month
	from customers c
	join recharges r 
	on c.customer_id =r.customer_id
	where r.amount_pkr>0),
total_revenue as(
	select operator, sum(revenue) as total_revenue, month
	from revenue 
	group by operator, month
	order by operator, month),
previous_revenue as(
	select operator, Total_revenue, month,
	lag(total_revenue) over(partition by operator order by month asc) as pre_revenue
	from total_revenue)
select operator, Total_revenue, month, pre_revenue,
round((total_revenue-pre_revenue)/nullif(pre_revenue,0)* 100::numeric,2) as growth_rate
from previous_revenue;