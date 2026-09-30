
CREATE SCHEMA IF NOT EXISTS `bq-learning-510104.dwh`
OPTIONS (location = 'US')
-------------

SELECT MIN(DATE(created_at)) AS ngay_dau, MAX(DATE(created_at)) AS ngay_cuoi
FROM `bigquery-public-data.thelook_ecommerce.order_items`
---------------------

CREATE OR REPLACE TABLE `bq-learning-510104.dwh.dim_date` AS
SELECT
  Cast(Format_date('%Y%m%d',d) as INT64) AS date_key,
  d AS full_date,
  Extract(year from d) AS year,
  Extract(quarter from d) AS quarter,
  Extract(month from d) AS month,
  format_date('%A',d) AS day_name
FROM UNNEST(GENERATE_DATE_ARRAY('2019-01-01', '2027-12-31')) AS d


-----------------------------------------

select
count(*) as row_amount
,min(date_key) as key_dau
,max(date_key) as key_cuoi
,min(full_date) as ngay_dau
,max(full_date) as ngay_cuoi
from
`bq-learning-510104.dwh.dim_date`

---------------------------------


CREATE OR REPLACE TABLE `bq-learning-510104.dwh.dim_users` AS
SELECT
  id AS user_id,
  gender,
  age,
  state,
  country,
  traffic_source
FROM `bigquery-public-data.thelook_ecommerce.users`


---------------------------

select
count(*) as sellr_amount
,count(distinct(user_id)) as id_uni
,(select count(*) from `bigquery-public-data.thelook_ecommerce.users` ) as source
from `bq-learning-510104.dwh.dim_users`

------------------------------------------


CREATE OR REPLACE TABLE `bq-learning-510104.dwh.dim_products` AS
SELECT
  id as product_id
  ,name
  ,category
  ,brand
  ,department
FROM `bigquery-public-data.thelook_ecommerce.products`


------------------------


Create or replace table `bq-learning-510104.dwh.fact_order_items` as
select
oi.id as order_item_id
,oi.order_id
,oi.user_id
,oi.product_id
,cast(format_date('%Y%m%d',date(oi.created_at)) as INT64) as order_date_key
,oi.status
,oi.sale_price
,p.cost
,oi.sale_price - p.cost as gross_profit

from `bigquery-public-data.thelook_ecommerce.order_items` oi
left join `bigquery-public-data.thelook_ecommerce.products` p
on p.id = oi.product_id

-----------------------------------------------------


select
count(*) as amount
,count(distinct(order_item_id)) as uni
,(select count(*) from `bigquery-public-data.thelook_ecommerce.order_items`) as item_source
,count(product_id) as product_num
,(select count(*) from `bigquery-public-data.thelook_ecommerce.products`) as pro_source
from `bq-learning-510104.dwh.fact_order_items`