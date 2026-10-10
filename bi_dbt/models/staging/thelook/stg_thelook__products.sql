-- Mục đích: staging cho products. Chỉ đổi tên, chọn cột; chưa có quy tắc nghiệp vụ.
-- Dùng source() vì products là bảng ngoài dbt (khai báo ở _thelook__sources.yml).
{{ config(materialized='view') }}

select
    id          as product_id,    -- đổi id thành product_id cho khớp tên khóa ở bảng fact
    name        as product_name,
    category,
    brand,
    department,
    cost,                         -- giá vốn, dùng để tính gross_profit ở mart
    retail_price
from {{ source('thelook', 'products') }}