-- Mục đích: bảng dimension sản phẩm cho Power BI (1 dòng = 1 sản phẩm).
-- Dùng ref() vì stg_thelook__products là model do dbt tạo.
-- materialized='table': lưu dữ liệu thật, là bản chụp tại lúc chạy.
{{ config(materialized='table') }}

select
    product_id,
    product_name,
    category,
    brand,
    department
from {{ ref('stg_thelook__products') }}