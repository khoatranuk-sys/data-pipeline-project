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

### Day 3

4xx là lỗi ở yêu cầu của mình (sai tham số, sai URL, sai key), phải sửa rồi mới chạy lại. 429 là mình gọi quá nhiều, cần chờ và gọi thưa hơn. 5xx là lỗi phía server, có thể thử lại. Mất mạng hoặc quá thời gian thì không có mã, cũng thử lại được.

## Ngày 4: Python cho pipeline (2) + Git

**1. Dry run và maximum_bytes_billed**
- Dry run (`check`): chỉ ước lượng xem query sẽ quét bao nhiêu MB, không chạy thật nên không tốn tiền.
- `run`: chạy thật và trả kết quả về DataFrame.
- `maximum_bytes_billed`: mức trần lượng dữ liệu bị tính tiền. Vượt mức này thì BigQuery từ chối chạy, không tính tiền (mức tối thiểu là 10 MB nên đặt 1 MB sẽ bị chặn).
- Dùng cả hai: dry run để xem trước, `maximum_bytes_billed` làm cầu chì.

**2. WRITE_APPEND và WRITE_TRUNCATE**
- `WRITE_APPEND`: nối dữ liệu vào bảng trên BigQuery. Chạy lại thì bị trùng, và không có lỗi nào được báo (bảng từ 21 dòng thành 42 dòng, COUNT và SUM ra gấp đôi).
- `WRITE_TRUNCATE`: xóa dữ liệu cũ của bảng rồi ghi dữ liệu mới, nên chạy lại bao nhiêu lần cũng ra cùng kết quả (idempotent). Đánh đổi: nếu dữ liệu mới chỉ có phần gần đây thì lịch sử cũ bị mất, nên với bảng tích lũy phải dùng cách khác.

**3. Commit và push**
- `git add`: chọn file đưa vào điểm lưu.
- `git commit`: lưu một điểm trong lịch sử, nằm trên máy mình.
- `git push`: đẩy các điểm lưu lên GitHub. `git pull` là chiều ngược lại, kéo từ GitHub về.

**4. .gitignore**
- `.gitignore` bảo Git lờ các file khớp tên hoặc mẫu trong đó: không hiện trong `git status`, không bị `git add` đưa vào commit, nên không lên GitHub. File vẫn nằm trên máy và dùng bình thường.
- `.env` bị chặn (dòng 151), còn `test.env` thì không vì tên khác, không khớp mẫu nào.
- `.gitignore` chỉ ngăn file chưa từng được commit; file đã lên GitHub rồi thì thêm vào `.gitignore` không gỡ được khỏi lịch sử.

**5. Lỡ push API key thật lên repo công khai**
- Việc đầu tiên: thu hồi (revoke) khóa cũ và tạo khóa mới.
- Chỉ xóa file là chưa đủ: Git còn lưu khóa trong lịch sử và có bot quét GitHub, nên khóa phải coi là đã lộ.
- Sau đó cập nhật khóa mới vào `.env` rồi mới dọn code trong repo.

## Ngày 5: Mini project (pipeline thời tiết)

**1. Logging thay cho print**
- Logging ghi từng bước kèm giờ và mức độ, ra màn hình và file `logs/weather_pipeline.log` (ghi nối thêm mỗi lần chạy). Pipeline chạy một mình ban đêm thì sáng hôm sau mở file log là biết đêm qua ổn hay không.
- `print` chỉ hiện lúc chạy, đóng cửa sổ hoặc chạy lại là mất, không có giờ và mức độ.
- Bốn mức: DEBUG (chi tiết để dò lỗi), INFO (tiến trình bình thường), WARNING (bất thường nhưng chưa hỏng, ví dụ ReadTimeout rồi retry thành công), ERROR (đã hỏng).

**2. Retry và backoff**
- Nên retry với lỗi tạm thời: 429 (gọi quá nhanh), 5xx (lỗi server), lỗi mạng (quá giờ, mất kết nối).
- Không retry với 4xx còn lại vì do request của mình (gọi lại vẫn ra cùng lỗi), phải dừng ngay và báo lỗi rõ ràng.
- Backoff là chờ lâu dần giữa các lần thử (2, 4, 8 giây) để không dồn thêm tải cho server đang quá tải và cho lỗi tạm thời có thời gian hết.

**3. Kiểm tra chất lượng trước khi nạp**
- Dữ liệu sai không báo lỗi mà làm số liệu sai khi người khác dùng; sửa sau khi nạp tốn công hơn chặn từ đầu.
- validate_weather kiểm tra: số dòng (3 thành phố × 7 ngày), giá trị thiếu, trùng (city, time), max nhỏ hơn min, mưa âm. Kiểm tra thất bại thì dừng, không nạp.
- Kiểm tra trùng (city, time) chính là kiểm tra grain: bảng thời tiết có grain là một thành phố một ngày.

**4. Script .py, hàm main() và mã thoát**
- Script chạy trọn quy trình bằng một lệnh; notebook chỉ để thử từng mảnh. main() cố định thứ tự lấy, làm sạch, kiểm tra, nạp.
- try/except trong main(): lỗi thì ghi log kèm dấu vết, các bước sau không chạy.
- Mã thoát gửi kết quả ra bên ngoài: 0 là thành công, 1 là thất bại, để công cụ lập lịch biết mà cảnh báo hoặc không chạy bước kế tiếp. Không có mã thoát thì pipeline hỏng mà bên ngoài vẫn thấy "đã chạy xong".
- Lần chạy thật đầu tiên gặp ReadTimeout ở Da Nang, retry thành công lần 2, log ghi lại đủ.


## Ngày 6: Ôn tập (grain, SCD, SELECT *)

**1. Grain**
- Grain là một dòng của bảng fact đại diện cho cái gì. `fact_order_items` có grain là một order item (một món hàng trong một đơn), nên một sản phẩm có thể xuất hiện ở rất nhiều dòng.
- Phải chốt grain trước vì nó quyết định bảng fact chứa được cột nào và nối được với dimension nào. Lẫn nhiều grain trong một bảng thì SUM và COUNT bị cộng trùng mà không báo lỗi.
- Các kiểm tra (đếm dòng, kiểm tra trùng) đều dựa vào grain. Ví dụ bảng thời tiết có grain là một thành phố một ngày, nên kiểm tra trùng (city, time).

**2. SCD 1 và SCD 2** (ví dụ khách đổi từ Hà Nội sang TP HCM)
- SCD 1: ghi đè, bảng chỉ còn TP HCM. Mất lịch sử, và doanh thu các đơn cũ cũng bị tính sang TP HCM, làm đổi báo cáo quá khứ.
- SCD 2: thêm dòng mới, khách có 2 dòng (HN và HCM). Có surrogate key mới, valid_from, valid_to, is_current. Dòng cũ được đóng lại (valid_to, is_current = false). Đơn cũ vẫn gắn với HN, đơn mới gắn với HCM, báo cáo quá khứ giữ nguyên.
- Cái giá của SCD 2: bảng dimension to hơn và phép nối phức tạp hơn (phải chọn đúng phiên bản).

**3. Vì sao tránh SELECT ***
- BigQuery lưu theo cột và tính tiền theo số byte của các cột mà query đọc, không phải số dòng trả về.
- SELECT * đọc tất cả cột nên đắt, và LIMIT không giảm chi phí.
- Cách làm đúng: chỉ chọn cột cần dùng, dry run để ước lượng, dùng maximum_bytes_billed làm cầu chì; sau này lọc theo cột partition (Tuần 2).

## Tuần 2 - Ngày 1: Load job

**Load job khác query job ở đâu?**
- Load job đưa dữ liệu từ bên ngoài (file trên máy hoặc trên Cloud Storage) lên bảng BigQuery.
- Query job đọc dữ liệu đã có trong bảng bằng SQL. `CREATE ... AS SELECT` cũng là query job (kết quả được ghi vào bảng mới).

**Vì sao Parquet ít phải đoán kiểu hơn CSV?**
- Parquet lưu sẵn schema trong file nên khi nạp, kiểu dữ liệu giữ y nguyên.
- CSV chỉ là chữ, nên BigQuery phải đoán (auto-detect chỉ lấy mẫu vài trăm dòng đầu) hoặc mình khai báo schema rõ.
- Parquet giữ kiểu đúng như file, chưa chắc là kiểu mình muốn: cột `time` ra TIMESTAMP vì lúc lưu là `datetime64`, trong khi bảng CSV ra DATE. Luôn kiểm tra kiểu cột sau khi nạp.

**Vì sao nạp theo lô được ưu tiên hơn nạp từng dòng?**
- Load job theo lô miễn phí; streaming bị tính phí riêng.
- Sandbox không hỗ trợ streaming nên chỉ nạp theo lô được.
- (Tính tiền theo cột là quy tắc của query job, không phải của load job.)

**Đã làm:** nạp bằng giao diện web (CSV, Parquet), bằng Python (`load_table_from_file`), và từ Cloud Storage công khai (`load_table_from_uri`, bảng `raw.us_states`, 50 dòng). Sandbox đọc được bucket công khai.