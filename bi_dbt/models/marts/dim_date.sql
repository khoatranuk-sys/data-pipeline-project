-- Mục đích: bảng lịch, mỗi dòng là một ngày, từ 2019-01-01 đến 2027-12-31.
-- Dùng làm dimension thời gian cho Power BI (khác dim_date trong dataset dwh).
-- Lưu ý: không viết dấu ngoặc nhọn trong comment vì Jinja vẫn xử lý.
{{ config(materialized='table') }}

with days as (
    -- generate_date_array tạo một mảng ngày; unnest biến mảng thành từng dòng
    select d as date_day
    from unnest(generate_date_array('2019-01-01', '2027-12-31', interval 1 day)) as d
)

select
    date_day,
    extract(year from date_day) as year_number,
    extract(quarter from date_day) as quarter_number,
    concat('Q', extract(quarter from date_day)) as quarter_name,
    extract(month from date_day) as month_number,
    format_date('%B', date_day) as month_name,
    format_date('%Y-%m', date_day) as year_month,
    -- thứ trong tuần: Monday = 1 đến Sunday = 7 (BigQuery mặc định Sunday = 1)
    mod(extract(dayofweek from date_day) + 5, 7) + 1 as weekday_number,
    format_date('%A', date_day) as weekday_name
from days