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