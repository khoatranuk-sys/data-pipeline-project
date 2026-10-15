-- Mục đích: bảng doanh thu thực tế dạng incremental. Lần đầu dựng đủ bảng,
-- các lần sau chỉ lấy đơn Complete trong 3 ngày gần nhất rồi ghép vào bảng.
-- Giống fct_net_sales (cùng grain: 1 mặt hàng trong 1 đơn Complete).

-- Cấu hình: kiểu incremental, khóa là order_item_id, ghép bằng MERGE
{{ config(
    materialized='incremental',
    unique_key='order_item_id',
    incremental_strategy='merge'
) }}

select
    oi.order_item_id,
    oi.order_id,
    oi.user_id,
    oi.product_id,
    oi.order_date,
    oi.sale_price,
    p.cost,
    oi.sale_price - p.cost as gross_profit
from {{ ref('stg_thelook__order_items') }} as oi
-- left join: giữ dòng không khớp sản phẩm (cost sẽ NULL, test bắt được)
left join {{ ref('stg_thelook__products') }} as p
    on oi.product_id = p.product_id
-- quy tắc doanh thu: chỉ tính đơn Complete
where oi.status = 'Complete'

-- Nhánh này chỉ chạy từ lần chạy thứ hai trở đi (khi bảng đã tồn tại)
{% if is_incremental() %}
  -- chỉ lấy đơn từ 3 ngày trước ngày mới nhất đã có trong bảng này
  and oi.order_date >= (
      select date_sub(max(order_date), interval 3 day)
      from {{ this }}
  )
{% endif %}