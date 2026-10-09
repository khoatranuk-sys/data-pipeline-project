-- Mục đích: model staging đầu tiên. Lấy bảng order_items thô, chỉ chọn cột cần, đổi tên và ép kiểu
--           cho sạch, để các model mart ở Ngày 4 dựa vào đây thay vì đọc thẳng bảng nguồn.
-- Staging chưa có quy tắc nghiệp vụ nào. Quy tắc "chỉ tính đơn Complete" nằm ở tầng mart (Ngày 4).

{{ config(materialized='view') }}       -- lưu thành VIEW: chỉ lưu câu SQL, tạo ra không quét dữ liệu

select
    id               as order_item_id,  -- đổi tên cho rõ nghĩa (id của chính bảng này)
    order_id,
    user_id,
    product_id,
    status,
    sale_price,
    created_at,
    date(created_at) as order_date      -- ép từ TIMESTAMP sang DATE, giống cột order_date ở bảng lab
from {{ source('thelook', 'order_items') }}   -- dbt thay chỗ này bằng `bigquery-public-data`.`thelook_ecommerce`.`order_items`