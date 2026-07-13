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

--Behavioral churn label: prepaid (90+ days since last recharge) vs postpaid (unpaid invoice, 60+ days since last billing), 
with recent_date as (
    select max(recharge_date) as recent_date
    from recharges),
prepaid_churn as (
    select r.customer_id,
    case when (d.recent_date - MAX(r.recharge_date)) >= 90 then 'Yes' else 'No' end as churned
    from recharges r
    cross join recent_date d
    group by r.customer_id, d.recent_date),
recent_billing_month as (
    select MAX(billing_month) as recent_month
    from invoices),
last_invoice as (
    select customer_id, billing_month, payment_date,
    ROW_NUMBER() over (partition by customer_id order by billing_month desc) as rn
    from invoices),
postpaid_churn as (
    select li.customer_id,
    case 
    	when (m.recent_month - li.billing_month) >= 60 and li.payment_date is null then 'Yes' else 'No' 
    end as churned
    from last_invoice li
    cross join recent_billing_month m
    where li.rn = 1)
select customer_id, churned from prepaid_churn
union all
select customer_id, churned from postpaid_churn;

-- Recharge frequency trend per prepaid customer: compares recharge count 
-- in their first 3 months vs most recent 3 months, labeled increasing/decreasing/stable
with old_dates as(
	select customer_id, min(recharge_date) as first_date 
	from recharges
	group by customer_id),
final_first_months as(
	select r.customer_id, count(r.amount_pkr) as recharge_in_first_3_months 
	from recharges r
	inner join old_dates o
	on r.customer_id = o.customer_id 
	where r.recharge_date < o.first_date + interval '3 months'
	group by r.customer_id 
	order by customer_id),
recent_dates as(
	select customer_id, max(recharge_date) as recent_date 
	from recharges
	group by customer_id),
final_recent_months as(
	select r.customer_id, count(r.amount_pkr) as recharge_in_recent_month
	from recharges r
	inner join recent_dates o
	on r.customer_id = o.customer_id 
	where r.recharge_date >= o.recent_date - interval '3 months'
	group by r.customer_id 
	order by customer_id)
select ffm.customer_id, ffm.recharge_in_first_3_months, frm.recharge_in_recent_month,
case
	when ffm.recharge_in_first_3_months > coalesce(frm.recharge_in_recent_month,0)  then 'decreasing'
	when ffm.recharge_in_first_3_months < coalesce(frm.recharge_in_recent_month,0)  then 'increasing'
	else 'Stable'
end as frequency_trend
from final_first_months ffm
left join final_recent_months frm
on ffm.customer_id =frm.customer_id;


























