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

## Tuần 2 - Ngày 2: Partitioning

**Partition giảm byte khi nào, và không giảm khi nào?** (số đo ở Cell 11, bảng nhỏ nên chỉ nhìn quy luật)
- Lọc theo cột partition (`order_date`): bảng partition quét ít hơn (356,5 KB còn 209,3 KB).
- Không lọc gì, lọc theo cột khác (`sale_price`), hoặc `SELECT * ... LIMIT 10`: không giảm (178,3 KB và 1832,7 KB, hai bảng bằng nhau).
- Muốn giảm byte mà bảng không partition: chọn ít cột (BigQuery tính theo số cột được đọc, không theo số dòng). Hai cách này cộng dồn được.
- Chỉ xem dữ liệu thì dùng Preview hoặc `list_rows` (không tạo query job nên không tính byte quét), không dùng `SELECT *`.

**Vì sao phải tạo thêm `fact_items_recent`?**
- Sau khi tạo, in `num_rows` của hai bảng (Cell 5): `fact_items_plain` 180.771 dòng, `fact_items_part` chỉ 22.817 dòng.
- Nhiều khả năng do sandbox gắn hạn 60 ngày cho partition (`expiration_ms` = 60 ngày), nên các tháng cũ bị xóa (suy luận, chưa kiểm chứng trực tiếp).
- So thẳng hai bảng thì bảng partition trông rẻ hơn chỉ vì ít dữ liệu hơn, không phải nhờ partition.
- `fact_items_recent` là bản sao không partition của toàn bộ 22.817 dòng đang có trong `fact_items_part`, nên hai bảng chỉ khác partition. Tháng 9 chỉ là tháng được chọn để thử (tháng nhiều dòng nhất).
- Bài học: sau khi tạo bảng luôn đối chiếu số dòng với bảng gốc.

**`require_partition_filter`**
- Khi bật, query phải có điều kiện lọc trên cột partition, nếu không bị từ chối (Cell 13); có điều kiện thì chạy được (Cell 14).
- Nó chỉ là cầu chì chặn quét nhầm toàn bảng, không làm query nhanh hơn hay rẻ hơn. Điều kiện `WHERE` trên cột partition mới giảm byte (đã đo), và thường nhanh hơn (chưa đo thời gian).
- `LIMIT` không thay được điều kiện lọc (Cell 15: thiếu lọc thì bị chặn).
- Tắt lại bằng `ALTER TABLE ... SET OPTIONS (require_partition_filter = FALSE)`.

**Lưu ý sandbox**
- Mọi bảng đều có hạn 60 ngày; bảng `dwh` hết hạn khoảng 29/11/2026.
- Tuần 3 khi bật billing: kiểm tra và gỡ hạn, tạo lại bảng partition với đủ dữ liệu (cách làm sẽ xác nhận sau).

## Tuần 2 - Ngày 3: Clustering và INFORMATION_SCHEMA.JOBS

**Clustering là gì, khác partition ở đâu?**
- Clustering sắp xếp dữ liệu bên trong bảng theo cột mình chọn (`CLUSTER BY product_id`, tối đa 4 cột, thứ tự cột có ý nghĩa) và chia thành các khối. Khi lọc theo cột đã cluster, BigQuery bỏ qua các khối không chứa giá trị cần tìm nên đọc ít byte hơn. Ví dụ: danh bạ xếp theo tên, tìm "Trần" thì mở thẳng phần chữ T.
- Partition chia bảng thành các ngăn riêng (thường theo ngày/tháng, cột ít giá trị khác nhau), dry run cho số chính xác. Clustering sắp xếp bên trong bảng (hoặc bên trong mỗi partition), hợp với cột nhiều giá trị (`product_id`, `user_id`), dry run chỉ là cận trên. Hai cách dùng được cùng nhau.

**Đo chi phí: bảng nhỏ và bảng lớn** (lọc `product_id` rồi `SUM(sale_price)`)
- Bảng nhỏ (`fact_items_plain` ~14 MB và `fact_items_clu`): hai bảng gần bằng nhau, billed đều 10 MB vì mức tối thiểu 10 MB và bảng quá nhỏ để chia khối.
- Bảng lớn (`big_plain` và `big_clu`, ~2,5 GB mỗi bảng, tạo bằng cách nhân dòng, đã xóa sau khi đo): bảng thường processed 499,26 MB (billed 500 MB), bảng clustered 6,97 MB (billed 10 MB), ít hơn khoảng 72 lần.
- Dry run của `big_clu` ra 6,97 MB, trùng số thật lần này. Nhưng với bảng clustered dry run chỉ là cận trên, không phải lúc nào cũng trùng.
- Chỉ lợi khi lọc theo cột đã cluster.

**Vì sao `big_plain` chỉ quét 499 MB dù bảng ~2,5 GB?**
- BigQuery tính theo cột được nhắc đến: query chỉ đọc `product_id` và `sale_price`, không đọc các cột còn lại. Chọn đúng cột và clustering là hai cách giảm chi phí khác nhau, cộng dồn được.
- Có thể kiểm chứng bằng Cell 5b (dry run theo 3 nhóm cột).

**`INFORMATION_SCHEMA.JOBS` là gì, dùng thế nào?**
- Là view hệ thống có sẵn của BigQuery, tự cập nhật khi có job chạy; chỉ đọc, không sửa, không xóa. Chứa thông tin về job, không chứa dữ liệu bán hàng.
- Gọi kèm vùng: `bq-learning-510104.region-us.INFORMATION_SCHEMA.JOBS`.
- Cột hay dùng: `creation_time`, `total_bytes_processed`, `total_bytes_billed`, `referenced_tables`. Giờ là UTC (giờ Việt Nam = UTC + 7).
- Cell 6 ban đầu ra bảng rỗng vì cửa sổ 3 giờ quá hẹp (các query chạy cách đó hơn 5 giờ), nới lên 24 giờ thì ra. Bảng rỗng là do bộ lọc, nên nới từng điều kiện để biết điều kiện nào loại mất dữ liệu.
- Không chọn `user_email` vì repo công khai.
- Ước tính tiền: `total_bytes_billed / 1024^4 * 6.25` (6,25 USD/TiB; sandbox không tính tiền thật). Query `big_plain` (500 MB) ước tính khoảng 0,003 USD.

**`f"""` và `rf"""` khác nhau thế nào?**
- `f` cho chèn biến bằng `{...}`; `r` giữ nguyên dấu `\`; `rf` là cả hai.
- Dùng `rf` khi SQL có `\` (ví dụ `r'\s+'` trong `REGEXP_REPLACE`). Chữ `r` bên trong SQL là của BigQuery, khác chữ `r` của Python.

**Ôn code Python cuối ngày (6 dòng)**
- `client = bigquery.Client(project=PROJECT, location="US")`: tạo kết nối Python với BigQuery. `client` dùng lại ở các cell sau để chạy query, xem bảng (`get_table`), liệt kê bảng, xóa bảng. `project` là project chạy query, `location` là vùng dữ liệu.
- `for name in ("fact_items_plain", "fact_items_clu"):` lặp qua từng phần tử, mỗi vòng tự **gán** phần tử vào `name`; khối thụt vào chạy 2 lần (không phải "khai báo").
- `cfg = bigquery.QueryJobConfig(dry_run=True)`: chỉ **tạo cấu hình**. Ước lượng xảy ra khi đưa `cfg` vào `client.query(sql, job_config=cfg)`. Dry run không chạy thật, không tốn quota, trả về số byte dự kiến.
- `job.result()`: chờ job chạy xong. Đọc `total_bytes_processed` quá sớm thì thường ra `None` (hàm `mb` biến thành 0,0 MB, dễ hiểu nhầm là miễn phí).
- `df = client.query(sql).to_dataframe()`: gửi SQL đi chạy rồi đưa kết quả thành DataFrame pandas nằm trong bộ nhớ máy, gán vào `df`. Tắt kernel là mất. `.to_dataframe()` tự chờ job xong.
- `client.delete_table(f"{PROJECT}.lab.{name}", not_found_ok=True)`: xóa bảng `lab.<name>`; `not_found_ok=True` thì bảng không tồn tại sẽ bỏ qua, không báo lỗi, nên chạy lại vẫn an toàn. Lệnh không hỏi xác nhận, coi là khó hoàn tác.
- Cần ôn lại ở Ngày 4: (1) `for` lặp qua và tự gán; (2) `QueryJobConfig(dry_run=True)` chỉ tạo cấu hình; (3) đọc số byte khi job chưa xong thường ra `None`; (4) dùng từ "gán".

**Đã làm:** tạo `fact_items_clu` (bản sao có clustering), thí nghiệm bảng lớn rồi xóa `big_plain` và `big_clu` (dataset `lab` còn 4 bảng: `fact_items_plain`, `fact_items_part`, `fact_items_clu`, `fact_items_recent`), đọc `INFORMATION_SCHEMA.JOBS`.

**Điều mình chưa chắc**
- Ngưỡng kích thước mà clustering bắt đầu có lợi (tài liệu nói chung khoảng 1 GB, không phải số cứng).
- Bảng vừa xóa có khôi phục được trong vài ngày không (chưa kiểm lại).
- `JOBS` có đúng là tên gọi tắt của `JOBS_BY_PROJECT` không (chưa kiểm lại).

## Tuần 2 - Ngày 4: IAM, view, materialized view

**IAM: cần hai role nào để chạy query?**
- IAM gắn ba thứ: ai (tài khoản), quyền gì (role), ở đâu (project, dataset, bảng).
- Người khác muốn chạy query cần cả Data Viewer (trên dataset hoặc bảng) và Job User (trên project). Thiếu một thì bị 403. Nguyên tắc quyền tối thiểu: cấp ở phạm vi nhỏ nhất đủ làm việc.
- Mình là Owner của project nên dùng tài khoản của mình thì không cần cấp thêm gì. `ds.access_entries` ra 4 mục; không in `entity_id` vì repo công khai.

**View khác bảng ở đâu, có rẻ hơn không?**
- View chỉ lưu câu SQL, không lưu dữ liệu; mỗi lần hỏi view thì BigQuery chạy lại câu SQL trên bảng gốc.
- Nên byte không giảm (hỏi qua `v_net_sales` và hỏi thẳng bảng gốc đều quét 3,15 MB, billed 10 MB, cùng kết quả). View giúp gọn và nhất quán: đổi quy tắc doanh thu ở một chỗ.

**Materialized view đổi gì lấy gì?**
- Lưu sẵn kết quả đã tính nên truy vấn đọc ít byte hơn rất nhiều (0,06 MB so với 3,15 MB), nhưng tốn thêm chỗ lưu và chi phí làm mới. Hợp với phép gom nhóm mà dashboard hỏi đi hỏi lại.
- Trên bảng nhỏ, billed vẫn 10 MB (mức tối thiểu): byte quét giảm nhưng tiền không đổi.
- Chưa kiểm chứng: MV tự cập nhật khi bảng gốc đổi, và phí làm mới sau khi bật billing.

**Quy tắc doanh thu:** chỉ tính đơn `Complete`. Giá trị trạng thái thật: Shipped, Complete, Processing, Cancelled, Returned (tên đúng là `Shipped`, không phải `Shipping`). Luôn `GROUP BY` xem giá trị thật trước khi viết `WHERE`.

**Ôn code Python cuối ngày**
- `t = client.get_table(...)`: lấy thông tin *về* bảng (tên cột, kiểu, số dòng), không tạo query job nên không tốn byte; không lấy dữ liệu bên trong.
- `return None if n is None else round(n / 1024 / 1024, 2)`: đổi byte sang MB; trả `None` thay vì 0 để lỗi đọc quá sớm lộ ra.
- `for entry in ds.access_entries:`: mỗi vòng gán một mục quyền (cả gói) vào `entry`; chạy 4 lần.
- `client.query(ddl).result()`: gửi lệnh rồi chờ xong; bỏ `.result()` thì cell sau có thể chạy trước hoặc đọc view cũ.
- `df = job.result().to_dataframe()`: chờ job xong rồi đưa kết quả thành DataFrame trong bộ nhớ; số byte lấy từ `job.total_bytes_processed`, không phải từ `df`.
- `f"""..."""`: chữ `f` thay `{PROJECT}` bằng giá trị biến; ba dấu ngoặc kép cho phép câu SQL xuống dòng.

## Tuần 2 - Ngày 5: dashboard đầu tiên bằng Data Studio

- Data Studio là tên mới của Looker Studio (đổi lại tháng 4/2026), khác Looker (trả phí, cho doanh nghiệp). Miễn phí; tiền (nếu có) chỉ đến từ query gửi xuống BigQuery. Đổi giao diện sang tiếng Anh: `https://datastudio.google.com/?hl=en`.
- Dashboard từ `lab.mv_net_sales_daily`: 4 thẻ, biểu đồ đường theo Year Month, Date range control. Số trên thẻ khớp SQL: toàn bộ 2.702.568 / 45.282 / 1.402.617 / 51,9%; khoảng 15/01/2025 đến 06/10/2026 là 1.529.873 / 25.658 / 793.321 / 51,9%.

**Những chỗ dễ nhìn nhầm**
- `Month` là tháng trong năm (cộng dồn các năm); dùng `Year Month` để có xu hướng.
- Bấm vào một điểm trên biểu đồ làm các thẻ lọc theo điểm đó (cross-filtering): bấm lại hoặc Reset.
- Thẻ có theo bộ lọc ngày nhưng cập nhật chậm hơn biểu đồ (từng thẻ một); thấy số cũ không phải lỗi. Cách chắc chắn: đối chiếu bằng SQL.
- `Record Count` đếm số dòng của nguồn (mỗi ngày một dòng) nên là số ngày, không phải số đơn.
- Margin là tổng chia tổng (`SUM(gross_profit) / SUM(net_revenue)`), không phải trung bình các tỷ lệ từng ngày.
- Tháng hiện tại chưa trọn làm đường biểu đồ rơi (tháng 10/2026 chỉ có 3 ngày); đỉnh 9/2026 có thật (3.447 dòng) do số dòng, không phải giá; dữ liệu mô phỏng.

**Data Studio gửi query thế nào (đọc từ `INFORMATION_SCHEMA.JOBS`)**
- Mỗi thẻ và biểu đồ là một query riêng, thường khoảng 4 query mỗi lần đổi bộ lọc; bộ lọc ngày thành `WHERE order_date >= ... AND ... <= ...`; mỗi thẻ chỉ đọc cột cần.
- Mỗi query chạy trong BigQuery khoảng 0,2 đến 0,5 giây, processed khoảng 0,04 đến 0,06 MB, billed 10 MB. Query giống hệt (`cache_hit = TRUE`) thì processed và billed bằng 0. Vậy cảm giác chậm không đến từ BigQuery.
- Khoảng 8 phút chỉnh bộ lọc có ít nhất 15 query billed 10 MB (khoảng 150 MB): sandbox không tính tiền, nhưng sau khi bật billing nhớ đặt quota.

**Ôn code Python cuối ngày**
- `df = job.result().to_dataframe()`: chờ job xong rồi đưa kết quả thành DataFrame, lưu trong bộ nhớ notebook (tắt kernel là mất).
- `for _, row in df_q.iterrows():`: `iterrows()` mỗi vòng đưa ra một cặp (số thứ tự, dữ liệu dòng); hai tên biến mở cặp ra (`_` nhận số thứ tự, `row` nhận dữ liệu dòng). Chỉ một tên thì nó nhận cả cặp và `row["query"]` báo `TypeError`.
- `print(row["query"])`: lấy giá trị cột `query` trong dòng hiện tại.
- `print("-" * 60)`: in dải 60 ký tự gạch ngang `-` (không phải `_`); thụt vào trong `for` nên chạy mỗi vòng.
- `QueryJobConfig(use_query_cache=False, maximum_bytes_billed=...)`: tắt cache không phải xóa cache, chỉ bảo query bỏ qua cache để số đo là số thật; `maximum_bytes_billed` là trần byte bị tính tiền (đổi MB sang byte), vượt thì từ chối chạy.
- `f"""..."""`: bỏ `f` thì BigQuery nhận nguyên `{PROJECT}`; bỏ `"""` thì SQL phải nằm trên một dòng (và chú thích `--` nuốt phần còn lại của dòng).
- In `len(df_q)` trước khi lặp: bảng rỗng thì `for` chạy 0 lần và không báo lỗi (Cell 14 ban đầu lọc 1 giờ nên rỗng).

**Cần ôn lại đầu ngày sau:** `use_query_cache=False` không xóa cache; `for _, row in ...iterrows()` (hai tên biến); phân biệt `_` với `"-"` và gõ đúng `iterrows`; `.to_dataframe()` đưa kết quả thành DataFrame, không đọc byte.

## Tuần 3 - Ngày 1: Billing, chi phí, gỡ hạn của sandbox

**Vì sao phải gỡ hạn trước khi làm tiếp?
 - Sandbox gắn hạn 60 ngày lên bảng và partition. Các tháng cũ của fact_items_part biến mất vì hạn partition (bảng chỉ còn 22.817 dòng thay vì 180.771).
 - Hạn nằm ở 3 tầng: cài đặt mặc định của dataset (chỉ ảnh hưởng đối tượng tạo sau), hạn riêng của từng bảng/view/MV (t.expires), hạn partition (expiration_ms). Phải gỡ cả 3.
 - Thứ tự: gỡ hạn trước, tạo lại bảng partition sau, nếu không bảng mới thừa hưởng hạn.

**Chi phí
 - Budget chỉ gửi thông báo, không chặn chi tiêu. Quota Query usage per day mới là cầu chì cứng nhưng chưa sửa được trên Free Trial; chờ nâng cấp trả phí.
 - Hiện tại cầu chì là maximum_bytes_billed trong code.

**Ôn code cuối ngày (Cell 4)

 - Vòng for lồng nhau: vòng trong chạy lại từ đầu mỗi lần vòng ngoài đổi; tổng 6 + 4 + 6 = 16 lần. Số lần phụ thuộc số đối tượng thật mà list_tables trả về.
 - ds.default_..._ms = None chỉ sửa bản sao trong Python; client.update_dataset(ds, [...]) mới gửi lên cloud. Thiếu dòng này thì cell vẫn chạy không lỗi nhưng cloud không đổi (sai âm thầm).
 - list_tables chỉ trả bản tóm tắt; get_table(item.reference) lấy thông tin đầy đủ (có expires), không tạo query job nên không tốn tiền.
 - if t.expires is not None: chỉ sửa khi có hạn; không có thì changed rỗng, không gọi update_table, nên chạy lại bao nhiêu lần cũng an toàn.
 - try/except: một bảng lỗi thì in LỖI rồi đi tiếp; bỏ đi thì cell dừng ở bảng lỗi. Vì lỗi bị nuốt nên phải tự đọc output tìm chữ LỖI.
 - Cần hiểu: ba lớp import (nạp thư viện), client = ... (kênh kết nối), client.xxx(...) (gửi yêu cầu thật). Không cần thuộc tên thuộc tính.

 - Cần ôn lại đầu ngày sau: (1) số lần vòng trong chạy; (2) hai dòng = None chỉ sửa trong Python, cần update_dataset; (3) list_tables khác get_table; (4) for _, row in df.iterrows() (hai tên biến, nhận cặp); (5) print viết thường.

 ## Tuần 3 - Ngày 2: cài dbt, khởi tạo project, kết nối BigQuery

**dbt là gì, nằm ở đâu trong luồng dữ liệu?**
- dbt biến các câu `SELECT` thành bảng hoặc view trong BigQuery theo đúng thứ tự phụ thuộc. Mình viết file `.sql` chỉ chứa `SELECT`, dbt thêm phần `CREATE` và chạy.
- dbt không chứa dữ liệu và không lấy dữ liệu từ API. Dữ liệu vẫn nằm trong BigQuery, dbt chỉ gửi SQL lên đó, nên tiền (nếu có) vẫn là tiền BigQuery theo byte quét.

**`profiles.yml` và `dbt_project.yml` khác nhau thế nào?**
- `profiles.yml`: dbt kết nối tới đâu (project, dataset, location, kiểu đăng nhập, `maximum_bytes_billed`). Nằm ngoài repo (`%USERPROFILE%\.dbt\`), không commit.
- `dbt_project.yml`: project dbt này làm gì (tên, thư mục model). Nằm trong `bi_dbt/`, có commit. Dòng `profile:` trong file này phải khớp tên khối ở `profiles.yml`.
- Giống dòng `client = bigquery.Client(project=PROJECT, location="US")` trong Python, nhưng khai báo bằng file thay vì viết vào code.

**Kết nối và cầu chì**
- Dùng `method: oauth` (đăng nhập gcloud đã có), không dùng service account vì không muốn file khóa gần repo công khai.
- `location` phải khớp vùng của dữ liệu (US); `dbt init` hỏi bằng số nên gõ nhầm ra EU, phải đọc dòng `location:` trong output `dbt debug`.
- `maximum_bytes_billed: 1000000000` là trần byte bị tính tiền cho mỗi query của dbt; vượt thì BigQuery từ chối chạy, không tính tiền. Cùng ý với `QueryJobConfig(maximum_bytes_billed=...)` trong Python.
- Cần hiểu: dbt chạy SQL trên BigQuery, `profiles.yml` chỉ cho dbt biết kết nối tới đâu. Không cần thuộc cú pháp YAML.

**Ôn code Python cuối ngày**
- `client.list_tables(ds)` nhận một dataset, trả danh sách bản tóm tắt; `client.get_table(item.reference)` nhận một bảng, trả thông tin đầy đủ (có `expires`).
- `ds.default_..._ms = None` chỉ sửa bản sao trong Python; `client.update_dataset(ds, [...])` mới ghi lên BigQuery. Thiếu dòng đó, cell vẫn chạy không lỗi nhưng cloud không đổi.
- `for _, row in df_q.iterrows():` mỗi vòng đưa ra một cặp (nhãn dòng, cả dòng); `row` là cả một dòng, `row["query"]` mới là một ô. Chỉ một tên biến thì `row` nhận cả cặp và báo `TypeError`.
- Khối `except` viết sai (`Print`, `talble_id`) chỉ nổ khi có bảng thật sự lỗi, và vì không còn `try` bắt nên cell dừng. Khối `except` cũng cần được thử riêng.
- Vòng `for` lồng nhau: vòng trong cộng dồn số bảng của từng dataset (4 dataset: 6 + 4 + 6 + 3 = 19 lần); số lần thật do `list_tables` trả về lúc chạy.
- `maximum_bytes_billed` so với bytes **billed** (tối thiểu 10 MB), không phải processed.

**Điều mình chưa chắc**
- Notebook Tuần 1-2 còn chạy ổn sau khi `protobuf` bị hạ xuống 6.33.6 không (import đã chạy được, chưa chạy lại cell thật).
- `dbt run` có tự tạo `dbt_dev` ở US không (`dbt debug` thì không).

**Cần ôn lại đầu ngày sau:** `row` là cả một dòng, `row["query"]` là một ô; khối `except` chỉ chạy khi có lỗi thật nên phải thử riêng; `list_tables` (dataset) khác `get_table` (một bảng); hai dòng gán `= None` cần `update_dataset`.

## Tuần 3 - Ngày 3: source và staging model

**`source()` và `ref()` khác nhau thế nào?**
- `source('thelook', 'order_items')`: trỏ tới bảng có sẵn bên ngoài dbt (ở đây là bảng trong `bigquery-public-data.thelook_ecommerce`). Giống dòng `FROM project.dataset.table`, nhưng khai báo một lần trong file `.yml`.
- `ref('stg_thelook__order_items')`: trỏ tới một model khác do dbt tạo (một file `.sql` mình đã viết). Hôm nay chỉ dùng `source`; Ngày 4 mart sẽ dùng `ref`.
- dbt đọc `source` và `ref` để biết thứ tự chạy các model.
- Cần hiểu: `source` = bảng ở ngoài dbt, `ref` = model do dbt tạo. Không cần thuộc cú pháp YAML hay `{{ }}`.

**Staging là gì?**
- Mỗi bảng nguồn một model, chỉ đổi tên, chọn cột, ép kiểu; chưa có quy tắc nghiệp vụ. Quy tắc "chỉ tính đơn `Complete`" để ở tầng mart.
- Trong BigQuery, `database` của dbt là project, `schema` của dbt là dataset.

**`view` khác `table` (và chi phí)**
- `view`: chỉ lưu câu SQL, không lưu dữ liệu. Tạo view không quét byte (`CREATE VIEW (0 processed)`), nhưng **mỗi lần có người truy vấn view** thì BigQuery chạy lại câu SQL trên bảng nguồn và tính byte. View luôn phản ánh nguồn hiện tại.
- `table`: dbt chạy `SELECT` và lưu kết quả, tốn byte một lần lúc tạo. Truy vấn bảng đó sau này **vẫn tốn byte** (theo cột đọc), nhưng thường nhẹ hơn vì phần tính toán nặng đã làm xong. Bảng là bản chụp lúc tạo.
- Chưa chắc: BigQuery tính tối thiểu theo bảng thế nào cho câu 1,38 MB hôm nay (có thể billed vẫn cỡ 10 MB).

**Chạy dbt và kiểm tra**
- `dbt compile --select <model>`: xem SQL đã biên dịch, không quét byte. `dbt run --select <model>`: tạo thật; luôn có `--select`, vì `models/example/` còn hai model mẫu.
- Lần `dbt run` đầu tiên dbt tự tạo dataset `dbt_dev` (US, không hạn tự xóa). Hoàn tác: xóa dataset `dbt_dev`.
- File `.yml` phải nằm trong `models/`, đuôi đúng `.yml` (Explorer có thể ẩn `.txt`; tạo file bằng VS Code).

**Bài học BI: nguồn công khai có thể đổi**
- View dbt có 181.466 dòng còn `lab.fact_items_plain` có 180.771 dòng. Trong cùng khoảng ngày chung, view có 174.936 dòng; chênh theo năm đổi dấu (2025: -1.002; 2026: +1.763).
- Giả thuyết (chưa chứng minh): bảng nguồn được cập nhật sau khi chụp bản lab. View đi theo nguồn hiện tại; bảng `lab` là bản chụp cố định.
- Cần hiểu: số liệu giữa hai ngày có thể khác khi nguồn thay đổi, nên đối chiếu trong cùng khoảng ngày và biết bảng nào là bản chụp.

**Ôn code Python cuối ngày**
- `for _, row in df.iterrows()`: `_` nhận nhãn dòng, `row` nhận cả một dòng, `row["query"]` là một ô.
- `try/except`: dòng lỗi nhảy sang `except`, vòng `for` vẫn đi tiếp; bỏ `try/except` thì cell dừng. Đã thử bảng không tồn tại: `NotFound`.
- `list_tables(dataset)` trả danh sách tóm tắt; `get_table(bảng)` trả thông tin đầy đủ.
- `SELECT 1` qua `stats` cho processed 0,0 MB, billed 0,0 MB: đường chạy query vẫn tốt sau khi `protobuf` bị hạ xuống 6.33.6.

**Điều mình chưa chắc**
- Nguyên nhân thật của chênh lệch số dòng (cần xem lại SQL tạo `lab.fact_items_plain`).
- Cách BigQuery tính byte tối thiểu cho câu truy vấn trên view.

**Cần ôn lại đầu ngày sau:** (1) view khác table về chi phí (cả hai đều tốn byte khi truy vấn); (2) `ref` trỏ tới model dbt, `source` trỏ tới bảng ngoài dbt; (3) `row` là cả một dòng; (4) hai dòng gán `= None` cần `update_dataset`; (5) `profiles.yml` (kết nối) khác `dbt_project.yml` (project làm gì).

## Tuần 3 - Ngày 4: mart model dùng ref

**Staging và mart khác nhau thế nào?**
- Staging: mỗi bảng nguồn một model, chỉ đổi tên, chọn cột, ép kiểu; chưa có quy tắc nghiệp vụ; dùng `view`. Mart: join, lọc, tính chỉ số, là bảng cho BI đọc; dùng `table`.
- Quy tắc "chỉ tính `Complete`" nằm ở mart (`fct_net_sales`). Nếu staging đã lọc sẵn thì về sau không còn dữ liệu `Returned` để phân tích.

**`ref` làm gì?**
- `ref('tên_file')` nằm trong `from` hoặc `join`, và chính nó khai báo quan hệ phụ thuộc (không có chỗ khai báo riêng, khác `source` phải khai báo trong `.yml`).
- dbt đọc mọi `ref`, dựng sơ đồ model nào đọc model nào, rồi tự xếp thứ tự chạy: gõ staging ở cuối lệnh nhưng log vẫn chạy nó đầu tiên; hai table không phụ thuộc nhau chạy song song.
- Viết tay `CREATE TABLE ... AS SELECT` sai thứ tự thì gặp `Not found: Table ...` (bảng chưa được tạo khi bảng sau cần đọc).
- Mình chỉ viết `SELECT`; dbt thêm `create or replace table` (hoặc view) theo `config(materialized=...)`.

**`dbt compile` và thư mục `target\`**
- `compile` dịch Jinja thành SQL thuần, không gửi lên BigQuery, không quét byte, không sửa file gốc. Bản dịch ở `target\compiled\`, bản chạy thật ở `target\run\`. `target\` và `logs\` do dbt tự tạo, bị `.gitignore` chặn.
- `compile` kiểm tra phần dbt (Jinja, `ref`), không kiểm tra SQL có đúng với BigQuery (sai tên cột chỉ lộ khi chạy thật).

**`left join` và kiểm tra mart**
- `left join` giữ dòng không khớp (cột bên products là NULL); `join` thường làm dòng biến mất âm thầm.
- Kiểm tra gồm hai phần bổ sung nhau: `countif(cost is null)` bắt NULL; so số dòng với staging bắt dòng bị mất hoặc nhân.
- Kết quả (09/10/2026): `fct_net_sales` 45.529 dòng = 45.529 id duy nhất, `cost` NULL = 0, bằng 45.529 dòng `Complete` của staging. Chỉ chứng minh mart khớp staging, chưa chứng minh staging khớp bảng public.

**View khác table về chi phí (đã đo)**
- Cùng phép `count(*), sum(sale_price)` với `status = 'Complete'`: view quét 3,16 MB (đọc lại bảng public, khoảng 181 nghìn dòng), table quét 0,35 MB (chỉ còn các dòng `Complete`); cả hai billed 10 MB do mức tối thiểu. Trên bảng nhỏ, quét ít hơn không làm rẻ hơn.
- `df_v.equals(df_t)` là `True`: hai kết quả giống hệt nhau.
- `dbt run`: `dim_products` 29,1 nghìn dòng (2,5 MiB), `fct_net_sales` 45,5 nghìn dòng (10,5 MiB).

**Scheduled query và dbt**
- Scheduled query lo "khi nào chạy"; dbt lo "chạy những gì, theo thứ tự nào, có kiểm tra không". Bổ sung nhau, không thay nhau. Chỉ thêm dữ liệu theo ngày mà không có khóa thì chạy lại sẽ bị trùng (như `WRITE_APPEND`); dbt incremental (Tuần 4) giải quyết bằng khóa.

**Ôn code Python cuối ngày**
- `QueryJobConfig(use_query_cache=False, maximum_bytes_billed=max_mb * 1024 * 1024)`: tắt cache chỉ là bỏ qua cache cho query này (không xóa gì); trần byte bị tính tiền, nhân `1024 * 1024` để đổi MB sang byte; vượt thì BigQuery từ chối chạy, không tính tiền.
- `df = job.result().to_dataframe()` rồi `print(... job.total_bytes_processed ...)`: `result()` chờ job xong; đọc byte quá sớm thì ra `None`. `df` là dữ liệu trả về, byte lấy từ `job`.
- `df_v.equals(df_t)`: `df_v` và `df_t` là DataFrame kết quả của hai câu SQL (không phải số byte); trả `True` hoặc `False`.

**Điều mình chưa chắc**
- Vì sao `fct_net_sales` (45.529) lệch bản `lab` (45.282): giả thuyết nguồn public đổi, chưa chứng minh.
- Truy vấn hai bảng billed 20 MB có đúng do mức tối thiểu 10 MB mỗi bảng không (mới một lần đo).

**Cần ôn lại đầu ngày sau:** (1) `use_query_cache=False` không xóa cache; (2) `df` chứa kết quả, byte nằm ở `job`; (3) `job.result()` chờ job xong; (4) view không lưu dữ liệu nên đọc lại bảng gốc; (5) `ref` khai báo ngay trong `from`/`join`.

## Tuần 3 - Ngày 5: Power BI Desktop, Import mode, quan hệ

**Import mode khác Data Studio thế nào?**
- Import: Power BI đọc bảng từ BigQuery mỗi lần Load/Refresh, rồi giữ bản sao hai bảng trong file `.pbix`. Lọc và bấm biểu đồ chạy trên bản sao này, không gọi BigQuery nên không tốn byte.
- Data Studio: mỗi thẻ và biểu đồ gửi một query xuống BigQuery mỗi lần đổi bộ lọc (khoảng 4 query, mỗi query billed tối thiểu 10 MB).
- Đánh đổi: dữ liệu chỉ mới đến lần Refresh gần nhất.

**Kết nối**
- Get data → Google BigQuery, Import mode, Billing Project ID `bq-learning-510104`, đăng nhập tab Organizational account bằng tài khoản Google của GCP. Tab Service Account Login cần file khóa JSON nên không dùng.
- Chỉ nạp `dim_products` và `fct_net_sales`; không nạp `stg_*` vì view đọc lại bảng public.
- Power BI không dùng `maximum_bytes_billed`; cầu chì hôm nay là bảng nhỏ.

**Quan hệ**
- `fct_net_sales.product_id` (nhiều) → `dim_products.product_id` (một), Many to one, Single, active.
- Bộ lọc đi từ bảng một (dimension) sang bảng nhiều (fact). Quan hệ là đường truyền bộ lọc: không có quan hệ thì mọi category ra cùng một tổng (tổng cả bảng fact).
- Phía "một" phải duy nhất: `dim_products` 29.120 dòng = 29.120 `product_id`; `fct_net_sales` không có `product_id` lệch (0).
- Cần hiểu: quan hệ là đường truyền bộ lọc, đi từ một sang nhiều. Không cần thuộc tên các tùy chọn trong hộp thoại.

**Đối chiếu số (11/10/2026)**
- SQL (Cell 2): 45.529 dòng = 45.529 id duy nhất; doanh thu 2.685.271,28; lợi nhuận 1.391.199,0 (processed 1,04 MB, billed 10 MB).
- Power BI: Count 45.529; tổng bảng theo category 2.685.271,28; card lợi nhuận 1,39M (làm tròn).
- Cell 3 (hai bảng) processed 0,57 MB, billed 20 MB.

**Hiển thị**
- Ngày dài `Wednesday, November 5, 2025` chỉ là định dạng hiển thị, đổi ở Column tools → Format.
- Cột số thực hiện nhiều chữ số lẻ do kiểu FLOAT; so sánh sau khi làm tròn 2 chữ số.

**Làm mới số liệu**
- `fct_net_sales` là bản chụp lúc `dbt run` cuối; Power BI là bản sao lúc Refresh cuối. Muốn số mới: `dbt run` (Anaconda Prompt, env `bi`, trong `bi_dbt`) rồi Refresh Power BI. Làm ngược thứ tự thì Power BI vẫn đọc bảng cũ.

**Ôn code Python cuối ngày**
- `QueryJobConfig(use_query_cache=False, maximum_bytes_billed=max_mb * 1024 * 1024)`: tắt cache chỉ là bỏ qua cache cho query này (không xóa gì); trần so với bytes billed (tối thiểu 10 MB); nhân `1024 * 1024` để đổi MB sang byte; vượt thì BigQuery từ chối chạy, không tính tiền.
- `df = job.result().to_dataframe()`: `result()` chờ job xong; đọc byte quá sớm thì ra `None`. Byte lấy từ `job`, `df` chỉ là kết quả của câu SQL.
- `client = bigquery.Client(project=PROJECT, location="US")`: tạo kênh kết nối; `client.query(...)` dùng kênh này gửi SQL và tạo `job`. `location` phải khớp vùng dataset (dbt có `location` riêng trong `profiles.yml`).

**Điều mình chưa chắc**
- Mỗi lần Refresh đọc bao nhiêu byte, qua job thường hay Storage Read API.
- Tên menu Power BI có thể khác tùy phiên bản.

**Cần ôn lại đầu ngày sau:** (1) bộ lọc đi từ một sang nhiều (mình từng nói ngược); (2) `job.result()` phải đứng trước khi đọc byte, nếu không là `None`; (3) `client` là kênh kết nối, `location` phải khớp vùng dataset; (4) làm mới số: `dbt run` rồi Refresh; (5) `use_query_cache=False` không xóa cache.

## Tuần 4 - Ngày 1: dbt test

**Test của dbt là gì?**
- Test khai báo trong file yml cạnh model. Mỗi test là một câu SQL dbt dựng từ mẫu có sẵn (`unique`, `not_null`, `accepted_values`, `relationships`), gửi lên BigQuery.
- Câu SQL trả về các dòng SAI. 0 dòng là PASS, từ 1 dòng là FAIL (`Got N results, configured to fail if != 0`). `N` là số dòng kết quả của test, không phải số dòng của bảng.
- Giống `validate_weather` ở Tuần 1 và các kiểm tra tay ở Tuần 3 (grain, join không mất dòng), nhưng chạy bằng một lệnh. Cần hiểu: test = "có dòng nào sai không?". Không cần thuộc cú pháp YAML.

**7 test đã viết** (`bi_dbt/models/marts/_marts__models.yml`)

| Bảng | Cột | Test | Kiểm tra gì |
|---|---|---|---|
| `dim_products` | `product_id` | `unique`, `not_null` | phía "một" của quan hệ hợp lệ |
| `dim_products` | `department` | `accepted_values` (Women, Men) | không có giá trị lạ |
| `fct_net_sales` | `order_item_id` | `unique`, `not_null` | đúng grain: 1 dòng = 1 order item |
| `fct_net_sales` | `product_id` | `not_null`, `relationships` | mọi `product_id` của fact có trong `dim_products` |

- `relationships` chỉ tìm khóa của fact không có trong dimension; không kiểm tra null hay trùng (đó là việc của test khác). Các test chạy độc lập, không theo thứ tự.
- Nếu có lỗi này mà không phát hiện, doanh thu của các dòng đó vẫn có trong tổng nhưng `category` rỗng (thường hiện (Blank) trong Power BI).
- Giá trị thật của `department` (kiểm bằng `GROUP BY` trước): Women 15.989, Men 13.131, tổng 29.120, không NULL.

**Xem test thật là SQL gì**
- dbt tự tạo file SQL ở `bi_dbt\target\compiled\bi_dbt\models\marts\_marts__models.yml\` (`_marts__models.yml` là một thư mục). Không viết tay, không commit (`target\` bị `.gitignore` chặn).
- `unique`: tạo CTE chọn cột khóa (bỏ dòng null), rồi `group by` khóa với `having count(*) > 1` (liệt kê khóa trùng).
- `accepted_values`: nhóm theo cột, rồi `where value_field not in ('Women', ...)` (liệt kê giá trị không có trong danh sách).

**Cho test fail để xem**
- `values: ['Women']` (cố ý thiếu `Men`): `FAIL 1`, `PASS=3 ERROR=1 TOTAL=4`. Đây là test fail chứ không phải lỗi SQL: SQL chạy tốt, nhưng trả về 1 dòng (giá trị lạ `Men`). Sửa thành `['Women', 'Men']` thì `PASS=4`.
- dbt không dừng khi một test fail; các test còn lại vẫn chạy.

**Lệnh và cảnh báo**
- Lệnh đúng: `dbt test --select dim_products fct_net_sales` (`test` là lệnh, `--select` là tùy chọn). Chọn một model thì dbt chạy mọi test đụng tới model đó, kể cả `relationships` đặt ở model khác.
- Gõ sai tên model (`dim_product`): không có lỗi đỏ, chỉ có dòng vàng `does not match any enabled nodes`; test của model đó không chạy mà cuối vẫn `Completed successfully`. Cách bắt: đọc dòng vàng và so `TOTAL` với số test mong đợi.

**Chi phí**
- Mỗi test là một query, billed tối thiểu 10 MB mỗi bảng (`relationships` đọc 2 bảng). Trần mỗi query là `maximum_bytes_billed: 1000000000` trong `profiles.yml`. Không tạo bảng. Cả buổi chưa đo (ước tính vài trăm MB).

**Ôn code Python cuối ngày**
- `rows = client.list_rows(table_id, max_results=20)`: `table_id` là chuỗi tên bảng (không phải cột); đọc thẳng dữ liệu đã lưu, không SQL nên không có job, không có bytes billed; dữ liệu về máy khi gọi `.to_dataframe()`. Trỏ vào `INFORMATION_SCHEMA.JOBS` thì `NotFound` vì đó là view hệ thống, `list_rows` gọi `get_table` trước. SQL hiểu cả view, `list_rows` chỉ đọc bảng có dữ liệu lưu sẵn.
- `df = job.result().to_dataframe()`: `result()` chờ job xong, `.to_dataframe()` đưa kết quả vào `df` (DataFrame trong bộ nhớ notebook, không phải bảng BigQuery). Byte lấy từ `job`, và `result()` phải đứng trước khi đọc byte, nếu không là `None`.
- `QueryJobConfig(use_query_cache=False, maximum_bytes_billed=max_mb * 1024 * 1024)`: tắt cache chỉ là bỏ qua cache (không xóa gì); nhân `1024 * 1024` đổi MB sang byte; vượt trần so với bytes billed thì BigQuery từ chối chạy, không tính tiền.

**Điều mình chưa chắc**
- Chi phí thật của `dbt test` (chưa đo).
- Cách dbt đếm `Got N results` bên trong (mình đoán bọc kết quả trong một câu đếm, chưa kiểm chứng).
- `list_rows` có đọc được view thường (như `v_net_sales`) hay không (đoán là không).
- `client.list_jobs` trả đủ `total_bytes_billed` hay không (chưa chạy).

**Cần ôn lại đầu ngày sau:** (1) `table_id` là tên bảng, `list_rows` không dùng SQL, `.to_dataframe()` mới lấy dữ liệu; (2) `df` nằm trong bộ nhớ, byte lấy từ `job` sau `result()`; (3) số trong `Got N results` là số dòng kết quả test; (4) `relationships` chỉ tìm khóa fact không có trong dimension, các test độc lập; (5) `* 1024 * 1024` đổi MB sang byte, trần byte của dbt nằm ở `profiles.yml`; (6) dòng WARNING vàng và `TOTAL`; (7) `for _, row in df.iterrows()` (hai tên biến) từ các tuần trước.

## Tuần 4 - Ngày 2: dbt docs

**Ý chính (4 ý cần nhớ)**
- `description` trong yml là ghi chú cho người đọc, đặt cạnh code (giống data dictionary): bảng là gì, 1 dòng là gì (grain), cột nghĩa là gì, quy tắc đã áp dụng. Khác với `data_tests` (kiểm tra dữ liệu, chạy bằng `dbt test`).
- `dbt docs generate` có hai pha: đọc file SQL và yml trên máy (ra `manifest.json`) rồi hỏi BigQuery lấy kiểu cột và số dòng (dòng `Building catalog`, ra `catalog.json`). Pha hai gửi query và tốn byte.
- `dbt docs serve` chỉ mở trang web trên máy từ các file đã tạo, không gọi BigQuery, miễn phí.
- Lineage do dbt tự dựng từ `source()` và `ref()` trong file SQL; yml khai báo source ở đâu và mô tả. `ref()` trong yml (như `relationships`) chỉ nối cái test với các bảng nó kiểm tra.

**Khung yml 3 tầng**
- `models` → `columns` → `data_tests`; mỗi tầng có `name`. Tên trong yml phải khớp tên file `.sql` và tên cột trong SQL (cột khai báo thừa không báo lỗi). Thụt lề bằng dấu cách quyết định cái nào nằm trong cái nào. Cần hiểu cấu trúc, không cần thuộc cú pháp.

**Đã thấy trên trang docs**
- `dim_products` có đúng 5 cột; kiểu dữ liệu lấy từ BigQuery (`INT64` là `INTEGER`), mô tả lấy từ yml. Cột Description trong BigQuery vẫn là `-`.
- Source (xanh lá) → staging (xanh dương) → mart; node đang chọn màu tím. `models/example/` hiện thành nhóm riêng và chưa chạy bao giờ. `orders` và `users` có trong cây Sources nhưng không có mũi tên.

**Chi phí của dbt** (đo bằng `INFORMATION_SCHEMA.JOBS`, nhận ra query dbt nhờ chú thích `/* {"app": "dbt"`)
- `dbt test` ngày 13/10: 15 query, 90 MB billed; query chạy lại giống hệt thì lấy từ cache (0 MB); đổi `accepted_values` thì ra query mới (10 MB).
- `dbt docs generate`: 2 query catalog (mỗi dataset một query), mỗi query đọc 5 bảng hệ thống, processed 40 MB, billed 50 MB (5 bảng × 10 MB tối thiểu), tổng 100 MB mỗi lần, lần chạy thứ hai không có cache. `dbt compile` và `dbt docs serve` không gửi query.
- Byte phụ thuộc cột được đọc, không phụ thuộc gom nhóm: `SELECT product_id, cost` và `SELECT COUNT(product_id), SUM(cost)` đều processed 0,69 MB; chỉ một cột thì 0,35 MB (45.529 dòng × 8 byte). Thời gian trên bảng nhỏ chủ yếu là độ trễ cố định (job 0,15 đến 0,26 giây nhưng cả query mất khoảng 3 giây).

**Ôn code Python cuối ngày**
- `QueryJobConfig(dry_run=True, use_query_cache=False)` rồi `for field in job.schema: print(field.name, field.field_type)`: dry run không đọc dữ liệu, chỉ kiểm tra SQL, ước lượng byte và trả về cấu trúc nên miễn phí; vòng `for` gán từng cột của `job.schema` vào `field`.
- `for _, row in df.iterrows():`: `iterrows()` trả một cặp (số thứ tự, dòng); `_` bỏ số thứ tự, `row` giữ dòng; `row["billed_mb"]` là số MB (không phải byte).
- `df = job.result().to_dataframe()`: `client.query()` trả `job` ngay, `job.result()` mới chờ xong; byte lấy từ `job` sau `result()`, không từ `df`.

**Điều mình chưa chắc**
- Bảng hệ thống thứ 5 mà `docs generate` đọc là bảng nào; vì sao query catalog không dùng cache.
- Lineage có vẽ node test không (hiện không thấy); `persist_docs` hoạt động thế nào.

**Cần ôn lại đầu ngày sau:** (1) `generate` hỏi BigQuery (tốn byte), `serve` chỉ mở file (miễn phí); (2) mũi tên lineage từ `source()` và `ref()` trong SQL, yml khai báo và mô tả; (3) `dry_run` không đọc dữ liệu, chỉ kiểm tra và ước lượng; (4) `iterrows()` trả cặp (số thứ tự, dòng), `_` bỏ số thứ tự; (5) `client.query()` không chờ, `job.result()` mới chờ; (6) khung yml 3 tầng và tên trong yml phải khớp SQL.

## Tuần 4 - Ngày 3: incremental model

**Ý chính (4 ý cần nhớ)**
- Incremental không tự tìm "dữ liệu thay đổi". dbt chỉ thêm một điều kiện lọc vào SQL (`is_incremental()`), lấy các dòng thỏa điều kiện, rồi `MERGE` vào bảng đích theo `unique_key`: `order_item_id` đã có thì ghi đè, chưa có thì thêm. Lần đầu bảng chưa tồn tại nên không có điều kiện lọc và dbt tạo đủ bảng.
- Điều kiện của mình: `order_date >= max(order_date) trong bảng - 3 ngày`. Cửa sổ lùi làm dbt lấy lại cả dòng đã có, nên số dòng `MERGE` (454) là kích thước cửa sổ, không phải số dòng đã đổi; tổng bảng không tăng (45.271 trước và sau).
- Với bảng nhỏ incremental không rẻ hơn: lần `CREATE TABLE` processed 10,5 MiB, lần `MERGE` 13,3 MiB (mình đoán vì `MERGE` còn đọc bảng đích, chưa kiểm chứng). Giá trị hôm nay là cơ chế, không phải tiết kiệm tiền.
- Rủi ro sai âm thầm: `MERGE` không xóa dòng, và câu SQL lọc `status = 'Complete'` nên đơn đã đổi sang `Returned` không được chọn ra, dòng cũ nằm lại trong bảng `inc` và doanh thu bị thổi phồng. Mở rộng cửa sổ không sửa được; 4 test của dbt cũng không bắt được (chúng không so với nguồn). Chỉ đối chiếu với nguồn mới bắt được.

**Model và test**
- File `bi_dbt/models/marts/fct_net_sales_inc.sql`: `materialized='incremental'`, `unique_key='order_item_id'`, `incremental_strategy='merge'`, cùng grain và cùng cột với `fct_net_sales`. Không sửa `fct_net_sales` (Power BI đang đọc).
- Thêm vào `_marts__models.yml` 4 test: `order_item_id` (`unique`, `not_null`), `product_id` (`not_null`, `relationships` sang `dim_products`). `dbt test --select fct_net_sales_inc`: `PASS=4 TOTAL=4`; `Found 7 models, 15 data tests, 4 sources`.
- Con số `Found`: 7 models = 2 mẫu + 2 staging + 3 mart; 15 test = 4 mẫu + 7 + 4 mới; 4 sources = 4 bảng khai báo.

**Đối chiếu số (nguồn public đã đổi)**
- Bảng `inc` 45.271 dòng khớp `staging_complete` hiện tại (45.271), còn `fct_net_sales` là bản chụp 45.529 dòng. Số `Complete` đã qua 3 giá trị theo thời gian: 45.282 (bản `lab`), 45.529, 45.271.
- So id giữa bản chụp cũ và bản mới: 34.191 id chỉ có ở bản cũ (đổi sang Shipped 13.871, Processing 8.871, Cancelled 6.770, Returned 4.576, không còn trong nguồn 103), 33.933 id chỉ có ở bản mới; chênh ròng 258. Nguồn không chỉ thêm dòng ở cuối mà đổi trạng thái đơn cũ trên diện rộng.
- Sau `MERGE`: `so_dong_inc` = `so_id_inc` = `so_dong_nguon` = 45.271, thiếu 0, thừa 0 (đúng tại lúc chạy, chưa chứng minh cửa sổ 3 ngày bắt được thay đổi).
- Cell 5: `max(order_date)` trong bảng `inc` là 2026-10-16 (lúc `MERGE` lần hai là 2026-10-18), mốc lọc 2026-10-13, có 1.241 đơn trong cửa sổ. Không so được với 454 vì hai cửa sổ khác nhau.

**Chi phí (đo bằng billed)**
- Cell 2 và Cell 3 đọc 3 bảng: billed 30 MB; Cell 4 và Cell 5 đọc 2 bảng: billed 20 MB, dù processed chỉ 3,5 đến 6,6 MB. Ủng hộ giả thuyết mức tối thiểu 10 MB tính theo từng bảng khác nhau (nhắc cùng một bảng nhiều lần vẫn tính một lần).
- `dbt test` hôm nay chưa đo bằng `INFORMATION_SCHEMA.JOBS` (ước tính khoảng 50 đến 60 MB).

**Khi nào dùng incremental**
- Dùng khi dữ liệu chỉ thêm theo ngày và lịch sử nguồn ổn định, hoặc nguồn có cột `updated_at` đáng tin. Giữ `table` khi bảng nhỏ hoặc nguồn sửa dòng cũ mà không biết dòng nào.
- Logistics: trạng thái đơn đổi lâu sau ngày đặt, nên lọc theo `order_date` sẽ bỏ sót. Cần cột "lần cập nhật cuối" hoặc cửa sổ rộng bằng chu kỳ giao và hoàn hàng. (Mình nghĩ bảng nguồn có `shipped_at`, `delivered_at`, `returned_at`, chưa kiểm tra.)

**Ôn code Python cuối ngày**
- `QueryJobConfig(use_query_cache=False, maximum_bytes_billed=max_mb * 1024 * 1024)`: bỏ qua cache (không xóa), trần so với bytes billed, nhân `1024 * 1024` đổi MB sang byte.
- `job = client.query(...)` trả `job` ngay (không chờ); `df = job.result().to_dataframe()` chờ xong rồi đưa kết quả vào `df`; byte lấy từ `job` sau `result()`.
- `for _, row in df.iterrows():` mỗi vòng đưa ra một cặp (nhãn dòng, cả dòng); `row["query"]` là một ô. Chỉ một tên biến thì `row` nhận cả cặp và lỗi `TypeError` nổ ở `row["query"]`.

**Điều mình chưa chắc**
- `max(order_date)` trong bảng `inc` tụt từ 2026-10-18 xuống 2026-10-16 sau `MERGE` (mình đoán có dòng được ghi đè với `order_date` mới).
- Trong 454 dòng `MERGE`, bao nhiêu dòng có giá trị thật sự khác.
- Vì sao `MERGE` processed nhiều hơn `CREATE TABLE`; staging view có bị quét hết dù có lọc ngày không.
- Thí nghiệm xóa 2 ngày cuối rồi `dbt run` (để thấy `MERGE` thêm dòng mới) chưa làm.

**Cần ôn lại đầu ngày sau:** (1) incremental chỉ lọc theo điều kiện rồi `MERGE` theo khóa, không tự biết dòng nào đổi; (2) cửa sổ là `max - 3 ngày` (trừ, không cộng); (3) 4 test của dbt không bắt được dòng đổi trạng thái ở nguồn; (4) `client.query()` không chờ, `job.result()` mới chờ; (5) khóa yml viết thường (`name`), `maximum_bytes_billed` có chữ `s`; (6) `iterrows()` trả cặp, lỗi nổ ở `row["query"]`.

## Tuần 4 - Ngày 4: Measure và DAX cơ bản

**Ý chính (4 ý cần nhớ)**
- Measure là công thức tính lại mỗi lần biểu đồ hiển thị, theo filter context của từng ô; không lưu giá trị. Calculated column tính một lần lúc Load/Refresh cho từng dòng của bảng và lưu trong bảng (file nặng hơn).
- Filter context: slicer lọc `dim_products`, bộ lọc đi qua quan hệ `product_id` từ một sang nhiều, `SUM` chỉ cộng các dòng fact còn lại. Dòng Total tính lại measure với filter context rỗng (không cộng các dòng). Không có quan hệ thì mọi category cùng một tổng (sai âm thầm, không có lỗi đỏ).
- Tỷ lệ phải là tổng chia tổng (`DIVIDE([Gross Profit], [Net Revenue])`). Trung bình các tỷ lệ cho mọi nhóm trọng số ngang nhau (Clothing Sets 4.360 doanh thu ngang Jeans 315.285), làm số sai.
- Explicit measure tốt hơn implicit: gọi lại được trong measure khác, sửa một chỗ, không bị đổi cách gộp nhầm, đặt tên và định dạng một lần. Implicit chỉ để xem thử.

**5 measure** (bảng `fct_net_sales`)

| Measure | Công thức DAX | Tương đương SQL |
|---|---|---|
| Net Revenue | `SUM(fct_net_sales[sale_price])` | `SUM(sale_price)` |
| Gross Profit | `SUM(fct_net_sales[gross_profit])` | `SUM(gross_profit)` |
| Order Items | `COUNTROWS(fct_net_sales)` | `COUNT(*)` |
| Orders | `DISTINCTCOUNT(fct_net_sales[order_id])` | `COUNT(DISTINCT order_id)` |
| Gross Margin % | `DIVIDE([Gross Profit], [Net Revenue])` | `SAFE_DIVIDE(SUM(gross_profit), SUM(sale_price))` |

- `DIVIDE` trả BLANK khi mẫu số 0; toán tử `/` trong DAX ra `Infinity`. Trong SQL, `a / b` báo lỗi `division by zero`, `SAFE_DIVIDE` trả NULL.
- `COUNTROWS` đếm dòng; đếm cột bằng `COUNT` bỏ qua NULL (bảng này không có NULL nên ra cùng số).

**Đối chiếu SQL và Power BI** (cùng bản chụp mart, không Refresh)

| | SQL | Power BI |
|---|---|---|
| Order items | 45.529 | 45.529 |
| Orders | 31.335 | 31.335 |
| Net Revenue | 2.685.271,28 | 2.685.271,28 |
| Gross Profit | 1.391.199,0 | 1.391.199,00 |
| Margin | 0,5181 | 51,8% |

- Theo department: Men 23.067 dòng, 1.427.482,26, lợi nhuận 738.332,74, 15.793 đơn, biên 51,7%; Women 22.462 dòng, 1.257.789,02, lợi nhuận 652.866,26, 15.542 đơn, biên 51,9%. Cộng lại khớp tổng.
- `Orders` cộng khớp (15.793 + 15.542 = 31.335), nhưng `DISTINCTCOUNT` nói chung không cộng được theo nhóm. Ở dữ liệu này đúng nếu mỗi đơn chỉ thuộc một department (chưa kiểm).
- Chi phí: Cell 3 processed 1,04 MB, billed 10 MB; Cell 4 (2 bảng) processed 1,09 MB, billed 20 MB. Power BI Import mode không tốn byte khi tạo measure và lọc.

**Ôn code Python cuối ngày**
- `job = client.query(sql, job_config=cfg)`: gửi SQL lên BigQuery và trả `job` ngay, không chờ. `df = job.result().to_dataframe()`: `result()` chờ job xong, `.to_dataframe()` đưa kết quả vào `df` (DataFrame trong bộ nhớ, tắt kernel là mất). Byte lấy từ `job` sau `result()`, không từ `df`; đọc byte quá sớm ra `None`.
- `QueryJobConfig(use_query_cache=False, maximum_bytes_billed=max_mb * 1024 * 1024)`: tắt cache chỉ là bỏ qua cache, không xóa gì; nhân `1024 * 1024` đổi MB sang byte; trần so với bytes **billed** (tối thiểu 10 MB mỗi bảng), không phải processed; vượt thì BigQuery từ chối chạy, **không tính tiền**.
- `print(len(df))`: kiểm tra số dòng mong đợi; có ích khi `df` dài hoặc trước vòng `for` (bảng rỗng thì vòng chạy 0 lần, không báo lỗi).

**Điều mình chưa chắc**
- Mỗi đơn chỉ thuộc một department hay có đơn lẫn Men và Women (chưa kiểm bằng SQL).
- Tên menu Power BI có thể khác theo phiên bản.

**Cần ôn lại đầu ngày sau:** (1) tổng chia tổng khác trung bình các tỷ lệ (trọng số); dòng Total tính lại measure với filter context rỗng; (2) `client.query()` không chờ, `job.result()` mới chờ, byte lấy từ `job`; (3) filter đi từ một sang nhiều qua `product_id`; xóa quan hệ thì mọi category cùng tổng; (4) `maximum_bytes_billed` so với billed, vượt thì không tính tiền; (5) calculated column tính lúc Load và lưu trong bảng, measure tính lúc hiển thị.