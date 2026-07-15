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
    case when (d.recent_date - max(r.recharge_date)) >= 90 then 'Yes' else 'No' end as churned
    from recharges r
    cross join recent_date d
    group by r.customer_id, d.recent_date),
recent_billing_month as (
    select max(billing_month) as recent_month
    from invoices),
last_invoice as (
    select customer_id, billing_month, payment_date,
    row_number() over (partition by customer_id order by billing_month desc) as rn
    from invoices),
postpaid_churn as (
    select li.customer_id,
    case when (m.recent_month - li.billing_month) >= 60 and li.payment_date is null then 'Yes' else 'No' 
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

-- Call-drop rate by tower, ranked worst to best (towers with 50+ calls only)
select tower_id,count(call_id) as total_calls, 
round(avg(dropped_flag::int)*100,2) as drop_rate_percentage,
dense_rank() over(order by round(avg(dropped_flag::int)*100,2) desc ) as tower_rank
from call_logs
where tower_id is not null
group by tower_id
having count(call_id)>=50
order by tower_rank asc;

--Cohort retention: for each signup-month cohort, what % of customers 
--showed activity at 3, 6, and 12 months after signup
with cohort as(
	select customer_id, signup_date , to_char(signup_date,'yyyy-mm') as cohort_month
	from customers
	order by customer_id),
activity as(
	select customer_id, recharge_date as activity
	from recharges
	union all
	select customer_id, payment_date as activity
	from invoices
	where payment_date is not null),
month_value_assign as(
	select c.customer_id, c.cohort_month,
	max(case when a.activity >= c.signup_date  + interval '3 month' then 1 else 0 end) as three_month,
	max(case when a.activity >= c.signup_date   + interval '6 month' then 1 else 0 end) as six_month,
	max(case when a.activity >= c.signup_date   + interval '12 month' then 1 else 0 end) as twelve_month
	from cohort c
	left join activity a
	on c.customer_id = a.customer_id
	group by c.customer_id, c.cohort_month )
select cohort_month,
count(*) as cohort_size,
round(100.0* sum(three_month)/count(*),2) as retained_3m,
round(100.0* sum(six_month)/count(*),2) as retained_6m,
round(100.0* sum(twelve_month)/count(*),2) as retained_12m
from month_value_assign 
group by cohort_month 
order by cohort_month;

-- Early vs late churn by operator: of churned customers, what % churned 
-- within their first 6 months of signup vs after 6 months
with customer_recent_activity as(
	select max(recharge_date) as last_activity
	from recharges),
prepaid_basic_info as(
	select c.customer_id, c.signup_date, max(r.recharge_date) as recent_activity, c.operator 
	from customers c
	left join recharges r
	on c.customer_id=r.customer_id
	group by c.customer_id, c.signup_date, c.operator),
prepaid_churned_customer as(
	select b.customer_id, b.signup_date, c.last_activity,b.recent_activity, b.operator,
	case when c.last_activity - b.recent_activity>=90 then 1 else 0 end as prepaid_churned
	from customer_recent_activity c
	cross join prepaid_basic_info b),
postpaid_customers_activity as(
	select max(payment_date) as last_activity
	from invoices),
postpaid_basic_info as(
	select c.customer_id, c.signup_date, max(payment_date) as recent_activity, c.operator
	from customers c
	left join invoices i
	on c.customer_id=i.customer_id 
	where i.payment_date is not null
	group by c.customer_id, c.signup_date, c.operator
	order by c.customer_id),
postpaid_churned as(
	select b.customer_id, b.signup_date, p.last_activity, b.recent_activity, b.operator,
	case when p.last_activity-b.recent_activity  >=60 then 1 else 0 end as postpaid_churned
	from postpaid_customers_activity p
	cross join postpaid_basic_info b),
prepaid_labels as(
	select customer_id, signup_date, recent_activity, operator,prepaid_churned, (recent_activity-signup_date) as gap
	,case when recent_activity-signup_date < 180 then 'early' else 'late' end as churned_label
	from prepaid_churned_customer
	where prepaid_churned =1),
postpaid_labels as(
	select customer_id, signup_date, recent_activity, operator,postpaid_churned, (recent_activity-signup_date) as gap
	,case when recent_activity-signup_date < 180 then 'early' else 'late' end as churned_label
	from postpaid_churned
	where postpaid_churned =1),
two_labels as(
	select customer_id, operator, churned_label
	from postpaid_labels 
	union all
	select customer_id, operator, churned_label
	from prepaid_labels),
count_of_customers as (
	select operator, churned_label, count(*) as total_churned_customers
	from two_labels
	group by operator, churned_label),
sum_of_count as (
	select *, (sum(total_churned_customers) OVER (PARTITION BY operator)) as total_sum
	from count_of_customers)
select *, round(100.0 * total_churned_customers/total_sum,2) as percentage_of_customers
from sum_of_count;

























