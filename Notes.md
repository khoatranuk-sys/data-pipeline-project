# Ngày 1: Thiết lập

## gcloud
- Đặt project mặc định:
```
gcloud config set project bq-learning-510104
```
- Tạo đăng nhập cho Python vào Google Cloud:
```
gcloud auth application-default login
```
- Xóa đăng nhập cũ:
```
gcloud auth application-default revoke
```

## Anaconda
- Tạo môi trường Python trong conda:
```
conda create -n bi python=3.11 -y
```
- Kích hoạt môi trường:
```
conda activate bi
```
- Cài thư viện:
```
pip install <tên thư viện>
```

## Git và GitHub
- Khai báo tên (gắn vào các commit):
```
git config --global user.name "..."
```
- Khai báo email (gắn vào các commit, không phải đăng nhập):
```
git config --global user.email "..."
```
- Kiểm tra phiên bản:
```
git --version
```

## Python + BigQuery (3 phần)
- Tạo client:
```python
from google.cloud import bigquery
client = bigquery.Client(project="bq-learning-510104")
```
- Viết SQL:
```python
sql = """
SELECT status, COUNT(*) AS amount
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY status
ORDER BY amount DESC
"""
```
- Chạy query và kiểm soát lưu lượng:
  - Ước lượng trước khi chạy:
```python
dry = client.query(sql, job_config=bigquery.QueryJobConfig(dry_run=True))
print(f"Se quet: {dry.total_bytes_processed / 1024 / 1024:.2f} MB")
```
  - Chạy thật, giới hạn 100 MB:
```python
config = bigquery.QueryJobConfig(maximum_bytes_billed=100 * 1024 * 1024)
df = client.query(sql, job_config=config).to_dataframe()
df
```

## Lỗi đã gặp
- **403 Forbidden** khi chạy query từ Python: đăng nhập nhầm tài khoản Google.
  - Xóa đăng nhập cũ: `gcloud auth application-default revoke`
  - Đăng nhập lại đúng tài khoản: `gcloud auth application-default login`
  - Gắn quota project: `gcloud auth application-default set-quota-project bq-learning-510104`


# Ngày 2:

## Khối 1: Khái niệm

- **Fact table:** mỗi dòng là 1 sự kiện và được nối với các dimension table bằng foreign key. 
- **dimension table:** mỗi dòng mô tả một đối tượng (khách, sản phẩm, ngày), dùng để lọc và nhóm, có khóa chính. ví dụ: user, product, order.
- **Grain:** 1 dòng của fact table đại diện cho cái gì. cần phải chốt trước khi thiết kế fact table. ví dụ: 1 dòng = 1 mặt hàng trong 1 đơn 
- **Star schema:** fact table ở giữa nối các dimension table xung quanh. fact table dùng foreign key nối với các primary key của các dimension table.
- **Surrogate key:** là khoá tự tạo ra (số nguyên hoặc hash), khi surrogate key được tạo ra thì đó cũng là khoá chính, khoá chính trước đó chỉ còn là mã nguồn. Cần khi nguồn đổi mã hoặc làm SCD Type 2. ví dụ khi 1 user đổi vị trí từ A sang B, thì table lúc này có 2 dòng, chỉ có 1 user_id. khi dó premary key chính là Surrogate key.
 
- **SCD** (Slowly Changing Dimension): cách xử lý khi dữ liệu trong bảng dimension thay đổi theo thời gian, có 3 kiểu phổ biến là Type 1, 2, 3.
- **SCD Type 1:** Ghi đè giá trị cũ. không giữ được giá trị lịch sử
- **SCD Type 2:** Thêm dòng mới cho mỗi lần đổi. các cột valid_from, valid_to, is_current và giữ được lịch sử đầy đủ
- **SCD Type 3:** Thêm cột giữ giá trị cũ. chỉ nhớ được 1 giá trị trước đó, đổi lần thứ hai thì mất giá trị cũ hơn.

## Khối 2: Khám phá thelook_ecommerce
### Cấu trúc 4 bảng

| Bảng | Mỗi dòng là gì | Loại | Khóa chính | Khóa ngoại | Số đo / mô tả |
|---|---|---|---|---|---|
| order_items | Một mặt hàng trong một đơn | Fact | id | order_id, user_id, product_id, inventory_item_id | Số đo: sale_price |
| orders | Một đơn hàng | Giống fact, nhưng không hợp grain | order_id | user_id | num_of_item |
| products | Một sản phẩm | Dimension | id | distribution_center_id | Mô tả: name, category, brand, department. Thuộc tính giá: cost, retail_price |
| users | Một khách hàng | Dimension | id | (không có) | Mô tả: age, gender, state, country, traffic_source |

### Khóa nối

- order_items.user_id → users.id
- order_items.product_id → products.id

### Đã kiểm tra bằng dữ liệu thật (BigQuery, chạy qua notebook)

- order_items: 180771 dòng và 180771 id duy nhất, nên id là khóa chính.
- product_id nối products: 0 dòng không khớp.
- user_id nối users: 0 dòng không khớp.

### Kết luận: chọn fact

order_items là fact table vì grain là 1 loại hàng trong 1 đơn hàng, nói cách khác là trong 1 đơn hàng có thể có rất nhiều item. cần product_id và
sale_price riêng cho từng món. orders chỉ có 1 dòng cho cả đơn và 1 đơn có thể từ 1 đến nhiều item, không có
product_id, nên mất chi tiết sản phẩm.

### Điều mình chưa chắc

- không có