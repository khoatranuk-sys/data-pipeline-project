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



# Ngày 2: Mô hình dữ liệu

## Khối 1: Khái niệm

- **Fact table:** mỗi dòng là 1 sự kiện đo được (ví dụ một mặt hàng bán ra). Bảng chứa số đo (ví dụ sale_price) và các foreign key nối với các dimension table.
- **Dimension table:** mỗi dòng mô tả một đối tượng (khách, sản phẩm, ngày), dùng để lọc và nhóm, có khóa chính. Ví dụ: users, products, date.
- **Grain:** 1 dòng của fact table đại diện cho cái gì. Cần chốt trước khi thiết kế fact table. Ví dụ: 1 dòng = 1 mặt hàng trong 1 đơn.
- **Star schema:** fact table ở giữa, các dimension table xung quanh. Fact table dùng foreign key nối với primary key của từng dimension table. Các dimension không nối với nhau, chỉ nối vào fact.
- **Surrogate key:** là khóa tự tạo ra (số nguyên hoặc hash). Khi surrogate key được tạo ra thì nó là khóa chính, khóa chính trước đó chỉ còn là mã nguồn. Cần khi nguồn đổi mã hoặc làm SCD Type 2. Ví dụ: khi 1 user đổi vị trí từ A sang B, bảng lúc này có 2 dòng nhưng chỉ có 1 user_id. Khi đó primary key chính là surrogate key.
- **SCD (Slowly Changing Dimension):** cách xử lý khi dữ liệu trong bảng dimension thay đổi theo thời gian, có 3 kiểu phổ biến là Type 1, 2, 3.
  - **SCD Type 1:** ghi đè giá trị cũ, không giữ được lịch sử.
  - **SCD Type 2:** thêm dòng mới cho mỗi lần đổi, có các cột valid_from, valid_to, is_current và giữ được lịch sử đầy đủ.
  - **SCD Type 3:** thêm cột giữ giá trị cũ, chỉ nhớ được 1 giá trị trước đó, đổi lần thứ hai thì mất giá trị cũ hơn.

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

- order_items: 180.771 dòng và 180.771 id duy nhất, nên id là khóa chính.
- product_id nối products: 0 dòng không khớp.
- user_id nối users: 0 dòng không khớp.

### Kết luận: chọn fact

order_items là fact table vì grain là 1 mặt hàng trong 1 đơn hàng, và 1 đơn có thể có nhiều mặt hàng. Mỗi dòng cần product_id và sale_price riêng cho từng món. orders chỉ có 1 dòng cho cả đơn, không có product_id, nên mất chi tiết sản phẩm.

### Điều mình chưa chắc

- Không có.

## Khối 3: Kết quả 4 bảng trong dataset dwh

Dataset: `bq-learning-510104.dwh` (location US). Chạy ngày 30/09/2026.
Dữ liệu nguồn là dataset công khai nên số dòng có thể thay đổi theo thời gian.

| Bảng | Số dòng | Khóa chính | Đã kiểm tra |
|---|---|---|---|
| dim_date | 3.287 | date_key | Phủ 2019-01-01 đến 2027-12-31, date_key đúng dạng YYYYMMDD |
| dim_users | 100.000 | user_id | Số id duy nhất = số dòng = số dòng bảng nguồn users |
| dim_products | 29.120 | product_id | Số id duy nhất = số dòng = số dòng bảng nguồn products |
| fact_order_items | 180.771 | order_item_id | Xem bên dưới |

### Kiểm tra fact_order_items

- Grain: 180.771 dòng = 180.771 order_item_id duy nhất, không có dòng trùng.
- Số dòng bằng bảng nguồn order_items (180.771), không mất dòng khi join products.
- cost và gross_profit không có giá trị NULL.
- order_date_key nối được dim_date: 0 dòng không khớp, join không nhân dòng.

### Truy vấn báo cáo

Doanh thu và lợi nhuận theo danh mục sản phẩm và quý, năm 2025: 104 dòng (4 quý x các danh mục sản phẩm).
Truy vấn hiện tính cả đơn Cancelled và Returned (để đối chiếu với tổng fact).
Khi tính doanh thu thực tế sẽ loại hai trạng thái này.

## Bài tập SCD

Khách A ở Hà Nội từ 01/01/2025, chuyển sang TP.HCM ngày 01/06/2025.

### Type 1: ghi đè

| user_id | city |
|---|---|
| A | TP.HCM |

### Type 2: thêm dòng mới

| user_key | user_id | city | valid_from | valid_to | is_current |
|---|---|---|---|---|---|
| 1 | A | Hà Nội | 2025-01-01 | 2025-06-01 | false |
| 2 | A | TP.HCM | 2025-06-01 | NULL | true |

Quy ước: một ngày thuộc dòng nào nếu `valid_from <= ngày < valid_to`.
Dòng hiện tại có `valid_to = NULL`, nên khi lọc cần xử lý NULL riêng.

### Type 3: thêm cột giá trị cũ

| user_id | city | previous_city |
|---|---|---|
| A | TP.HCM | Hà Nội |

Type 3 chuẩn không có cột ngày chuyển, và chỉ nhớ được 1 giá trị trước đó.

### Đơn hàng ngày 15/03/2025 của khách A tính vào thành phố nào?

| Kiểu | Thành phố | Lý do |
|---|---|---|
| Type 1 | TP.HCM | Ngày 01/06 Hà Nội bị ghi đè, bảng không còn lưu |
| Type 2 | Hà Nội | 15/03 nằm trong khoảng [2025-01-01, 2025-06-01) của dòng Hà Nội |
| Type 3 | TP.HCM | Báo cáo theo city chỉ nối vào giá trị mới nhất, Hà Nội chỉ nằm ở previous_city |

### Kết luận: vì sao Type 2 quan trọng nhất

Type 2 giữ lại từng lần thay đổi của khách kèm khoảng thời gian hiệu lực, nên mỗi đơn hàng được gắn với thành phố đúng tại thời điểm đặt hàng. Khi tính doanh thu theo khu vực, kết quả vì vậy chính xác hơn Type 1 và Type 3.

### Ghi chú

- dim_users trong BigQuery hiện là Type 1 (mỗi khách một dòng, user_id là khóa chính).
- Type 2 làm trên dữ liệu thật ở Tuần 4 bằng dbt snapshot.