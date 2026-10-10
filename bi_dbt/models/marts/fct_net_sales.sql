-- Mục đích: bảng fact doanh thu thực tế. Grain: 1 dòng = 1 mặt hàng trong 1 đơn Complete.
-- Quy tắc nghiệp vụ (chỉ tính Complete) nằm ở đây, không nằm ở staging.
-- Không viết dấu ngoặc nhọn của dbt trong dòng chú thích: dbt vẫn xử lý chúng.
{{ config(materialized='table') }}

select
    oi.order_item_id,                          -- khóa chính (grain)
    oi.order_id,
    oi.user_id,
    oi.product_id,                             -- khóa nối sang dim_products
    oi.order_date,
    oi.sale_price,
    p.cost,
    oi.sale_price - p.cost as gross_profit
from {{ ref('stg_thelook__order_items') }} as oi
-- left join: nếu có sản phẩm không khớp thì dòng vẫn giữ lại (cost = NULL) để kiểm tra bắt được,
-- thay vì join thường làm dòng biến mất âm thầm.
left join {{ ref('stg_thelook__products') }} as p
    on oi.product_id = p.product_id
where oi.status = 'Complete'                   -- quy tắc doanh thu đã chốt