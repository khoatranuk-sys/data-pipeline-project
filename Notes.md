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

## Tuần 4 - Ngày 5: dim_date và star schema trong Power BI

**Ý chính (4 ý cần nhớ)**
- `dim_date` là dimension thời gian, mỗi dòng một ngày; làm bằng SQL thuần (`generate_date_array`) nên không đọc bảng nào và dbt không quét byte. Khóa `date_day` nối với `fct_net_sales.order_date`.
- Star schema trong Power BI: fact ở giữa, các dimension (`dim_products`, `dim_date`) nối vào fact, phía một là dimension, hướng lọc Single. Hai dimension không nối với nhau; fact là chỗ hai bộ lọc giao nhau (AND), không truyền bộ lọc giữa các dimension.
- Test `relationships` từ fact sang dim tìm giá trị CÓ trong fact nhưng KHÔNG có trong dimension. Nếu lọt, dòng đó hiện thành (Blank) trong ma trận theo `year_number`, Total vẫn đủ nên không có lỗi đỏ.
- `month_number`, `weekday_number` có để Power BI sắp xếp tên tháng và thứ đúng thứ tự (mặc định xếp theo bảng chữ cái). Tắt Auto date/time để Power BI không tự sinh bảng ngày ẩn.

**Đã làm**
- File `bi_dbt/models/marts/dim_date.sql` (`table`), 3.287 dòng. Test: `date_day` `unique` + `not_null`, `fct_net_sales.order_date` `relationships`. `dbt test --select dim_date fct_net_sales` `PASS=7`; `Found 8 models, 18 data tests`.
- Đối chiếu: 0 `order_date` không khớp; doanh thu theo năm từ SQL (Cell 4) khớp ma trận Power BI; tổng 2.685.271,28; Women 1.257.789,02 và 22.462 dòng.
- Chi phí: Cell 2 billed 10 MB (processed 0,03), Cell 3 và Cell 4 billed 20 MB (hai bảng). Mức tối thiểu 10 MB tính theo từng bảng vẫn là giả thuyết (chưa có tài liệu xác nhận).

**Lỗi và chỗ dễ nhầm**
- Lỗi chính tả `data_test` (đúng là `data_tests`): chỉ có dòng vàng, test bị bỏ qua; số test hiện `17` thay vì `18` là dấu hiệu.
- "One to many" và "Many to one" là hai cách đọc cùng một quan hệ; cái cần đúng là phía "một" là dimension.
- Ẩn cột: chuột phải → Hide; View hidden chỉ là công tắc hiện lại.

**Ôn code Python cuối ngày**
- `df = job.result().to_dataframe()`: `client.query()` gửi job và trả `job` ngay (không chờ); dòng này chờ job xong rồi đưa kết quả vào `df`. `df` là DataFrame trong bộ nhớ (không phải table ở BigQuery), chỉ chứa dòng kết quả; byte processed/billed nằm ở `job`, đọc sau `result()`.
- `for _, row in df.iterrows():` mỗi vòng đưa ra cặp (nhãn, cả một dòng); `_` bỏ nhãn, `row` giữ cả dòng, `row["net_revenue"]` là một ô; vòng chạy đúng bằng số dòng của `df` (Cell 4: 8).
- `QueryJobConfig(use_query_cache=False, maximum_bytes_billed=max_mb * 1024 * 1024)`: bỏ qua cache (không xóa), nhân `1024 * 1024` đổi MB sang byte, trần so với bytes billed, vượt thì từ chối chạy và không tính tiền.

**Điều mình chưa chắc**
- Có cần Mark as date table cho time intelligence ở Tuần 5 không (hộp thoại ghi "not recommended").
- Chi phí thật của 7 test hôm nay.

**Cần ôn lại đầu ngày sau:** (1) dòng `df = ...` không gửi job, `df` không phải bảng BigQuery; (2) `relationships` tìm giá trị có trong fact nhưng không có trong dimension, không phải NULL; dòng lọt hiện thành (Blank); (3) processed nhỏ vì chỉ đọc cột cần; (4) bộ lọc đi một chiều từ dimension sang fact, fact là chỗ giao nhau (AND); (5) đọc số `Found ... data tests` và dòng vàng sau mỗi lệnh dbt.

## Tuần 5 - Ngày 1: CALCULATE và filter context

**Ý chính (4 ý cần nhớ)**
- `CALCULATE(biểu thức, filter...)` tính biểu thức trong filter context đã bị sửa. Filter trong `CALCULATE` ghi đè filter cũ **trên cùng cột** (từ slicer hoặc từ dòng bảng), còn filter ở cột khác vẫn đi qua. Ví dụ: `Net Revenue Men` ở dòng Women hiện số của Men, nhưng khi chọn 2024 nó chỉ là Men của 2024.
- `REMOVEFILTERS(dim_products)` chỉ gỡ filter của bảng `dim_products`; filter từ `dim_date` vẫn đi qua quan hệ sang fact. Dùng để lấy mẫu số "tổng": `DIVIDE([Net Revenue], [Net Revenue All Products])` ra tỷ lệ theo từng năm đang chọn.
- `dbt run` PASS chỉ nghĩa là SQL chạy được và bảng được tạo; `dbt test` PASS chỉ nghĩa là cấu trúc ổn (`unique`, `not_null`, `accepted_values`, `relationships`). Cả hai không nói giá trị có đổi so với lần trước hay không.
- Nguồn public mô phỏng đổi cả đơn năm cũ: doanh thu 2025 đổi từ 624.117,64 sang 615.360,21 dù test 11/11 PASS. Muốn bắt thay đổi này phải đối chiếu với nguồn hoặc bản chụp trước, như Cell 2 và Cell 3.

**4 measure mới** (bảng `fct_net_sales`)

| Measure | Công thức DAX | Tác dụng |
|---|---|---|
| Net Revenue Men | `CALCULATE([Net Revenue], dim_products[department] = "Men")` | ghi đè filter department thành Men |
| Net Revenue 2025 | `CALCULATE([Net Revenue], dim_date[year_number] = 2025)` | ghi đè filter năm thành 2025, slicer năm không làm đổi |
| Net Revenue All Products | `CALCULATE([Net Revenue], REMOVEFILTERS(dim_products))` | gỡ filter department, giữ filter năm |
| Revenue % of Total | `DIVIDE([Net Revenue], [Net Revenue All Products])` | tổng chia tổng, ra tỷ lệ theo năm đang chọn |

**Đối chiếu trên bản chụp cũ (45.529 dòng) rồi bản chụp mới (45.285 dòng, sau `dbt run`)**

| | Bản chụp cũ | Bản chụp mới |
|---|---|---|
| Net Revenue | 2.685.271,28 | 2.707.334,88 |
| Gross Profit | 1.391.199,00 | 1.405.850,55 |
| Men | 1.427.482,26 | 1.418.890,23 |
| Women | 1.257.789,02 | 1.288.444,65 |
| Năm 2025 | 624.117,64 | 615.360,21 |
| Năm 2024 | 406.979,98 | 406.293,31 |

- Bản mới: `fct_net_sales` 45.285 dòng = 45.285 `order_item_id`, ngày đặt 2019-01-21 đến 2026-10-22 (ngày cuối nằm sau ngày hôm nay, củng cố nhận định dữ liệu mô phỏng). Power BI sau Refresh khớp SQL (Men + Women, 2025, 2024, tổng).
- `dbt run` `PASS=2` (45,3 nghìn dòng; 29,1 nghìn dòng). `dbt test` `PASS=11 TOTAL=11`: gồm cả `relationships` của `fct_net_sales_inc` vì nó đụng tới `dim_products`.
- Chi phí: Cell 2 billed 20 MB (2 bảng), Cell 3 billed 10 MB (1 bảng). Power BI Import mode không tốn byte khi lọc và bấm slicer.

**Chỗ dễ nhầm**
- Slicer vừa chọn mà Matrix chưa đổi: chờ vài giây rồi mới kết luận (chụp ảnh quá sớm sẽ thấy số cũ).
- `[7:6]` trong lỗi BigQuery là dòng 7, cột 6 của câu SQL (chỗ dấu backtick mở bị thiếu dấu đóng), không phải dòng trong cell.

**Ôn code cuối ngày**
- `job = client.query(sql, job_config=cfg)`: gửi job lên BigQuery và trả `job` ngay, không chờ; `job` là "phiếu theo dõi", chưa phải kết quả.
- `QueryJobConfig(use_query_cache=False, maximum_bytes_billed=max_mb * 1024 * 1024)`: bỏ qua cache (không xóa gì) để `processed` và `billed` phản ánh lần chạy thật; nhân `1024 * 1024` đổi MB sang byte.

**Điều mình chưa chắc**
- Nguyên nhân thật của việc doanh thu 2025 đổi (đổi trạng thái đơn hay xóa đơn); chưa so id giữa hai bản chụp.
- Chi phí thật của 11 test và của Refresh Power BI (3 bảng, có thể billed tối thiểu 10 MB mỗi bảng).

**Cần ôn lại đầu ngày sau:** (1) `CALCULATE` ghi đè filter cùng cột, filter cột khác vẫn đi qua; (2) `REMOVEFILTERS(bảng)` chỉ gỡ filter của bảng đó; (3) test dbt kiểm cấu trúc (`unique`, `not_null`, `accepted_values`, `relationships`), `dbt run` PASS chỉ là SQL chạy được, cả hai không đối chiếu giá trị với nguồn.

## Tuần 5 - Ngày 2: time intelligence (YTD, cùng kỳ, YoY)

**Ý chính (4 ý cần nhớ)**
- Hàm time intelligence vẫn là `CALCULATE`: chỉ đổi tập ngày của filter (cả năm tới giờ, hoặc lùi một năm). Filter ngày của một dòng Matrix là cả tập ngày của tháng đó, không phải một giá trị. Các filter trong `CALCULATE` trên cùng cột `date_day` giao nhau (AND).
- `TOTALYTD` tính lại từ đầu ở mỗi ô (từ 01/01 đến cuối kỳ của dòng), không cộng nối tiếp từ dòng trên. Fact hết dữ liệu mà lịch vẫn dài thì tháng 11, 12 vẫn hiện YTD của tháng cuối có dữ liệu.
- Trong phép trừ của DAX, BLANK coi như 0: `[Net Revenue] - [ly]` thành `0 - ly` nên YoY ra −100% dù doanh thu chỉ là chưa có dữ liệu. Sửa ở `ly` (cho `ly` trống) thì `DIVIDE` trả trống.
- Mark as date table: bật hay tắt đều ra cùng số trên mô hình này (kiểm bằng 4 cột Matrix 2025). Kết luận chỉ cho mô hình này, không phải quy tắc chung.

**3 measure** (bảng `fct_net_sales`; trong mô hình đặt tên `ytd`, `ly`, `YoY %`)

| Measure | DAX | Tương đương SQL |
|---|---|---|
| ytd | `IF(ISBLANK([Net Revenue]), BLANK(), TOTALYTD([Net Revenue], dim_date[date_day]))` | `SUM(rev) OVER (PARTITION BY y ORDER BY mth)` |
| ly | `VAR LastData = CALCULATE(MAX(fct_net_sales[order_date]), REMOVEFILTERS(dim_date))` rồi `CALCULATE([Net Revenue], SAMEPERIODLASTYEAR(dim_date[date_day]), dim_date[date_day] <= EDATE(LastData, -12))` | `LAG(rev) OVER (PARTITION BY mth ORDER BY y)`, cắt đuôi cùng ngày-tháng |
| YoY % | `DIVIDE([Net Revenue] - [ly], [ly])` | `SAFE_DIVIDE(rev - ly, ly)` |

- `LastData` luôn là ngày cuối có dữ liệu của cả bảng (22/10/2026) nhờ `REMOVEFILTERS(dim_date)`, không đổi theo slicer. `EDATE(LastData, -12)` lùi 12 tháng (một năm) thành 22/10/2025, khớp với `SAMEPERIODLASTYEAR` lùi một năm. `<= EDATE(...)` là bộ lọc "cắt đuôi": chỉ cắt được khi tập ngày sau khi lùi một năm vượt qua mốc (như 2026 lùi thành 2025); chọn 2025 thì `ly` là cả 2024 và mốc không có tác dụng.
- Ở dòng 2026-10, `SAMEPERIODLASTYEAR` ra 01/10 đến 31/10/2025, cắt đuôi còn 01/10 đến 22/10/2025.

**Đối chiếu SQL và Power BI** (cùng bản chụp, không Refresh)
- Năm 2025 (Cell 2): 12 tháng khớp cả `net_revenue`, `ytd`, `ly`, `yoy` (làm tròn). Total: 615.360,21 / ly 406.293,31 / YoY 51,46%. `ytd` tháng 12 bằng tổng năm.
- Năm 2026 sau khi sửa `ly` (Cell 3): từ 1/1 đến 22/10, 2026 là 982.813,17 và 2025 là 473.647,45; riêng tháng 10 cùng kỳ: 2026 là 180.243,98, 2025 là 37.273,31. Matrix 2026: Total `ly` 473.647,45, YoY 107,50%; dòng 2026-10 `ly` 37.273,31, YoY 383,57%. Tháng 11 và 12/2026 không còn hiện (mọi measure trống).
- YoY lớn (143% ở tháng 9/2026, 383% ở tháng 10) là do dữ liệu mô phỏng tăng mạnh, không phải lỗi DAX.
- Chi phí: Cell 3 processed 0,69 MB, billed 10 MB (một bảng). Power BI Import mode không tốn byte khi tạo measure, lọc, bấm slicer.

**Ba chỗ sai âm thầm đã gặp** (không có lỗi đỏ)
- `ytd` tháng 11 và 12/2026 hiện 982.813,17 dù Net Revenue trống; YoY −100% ở hai tháng đó.
- Total 2026 so với cả năm 2025 (615.360,21) nên YoY chỉ 59,71%; so đúng cùng kỳ là 107,50%.
- Tháng 10/2026 chưa trọn bị so với cả tháng 10/2025.

**Slicer còn năm 2027:** do `dim_date` phủ 2019 đến 2027. Không rút ngắn `dim_date`. Kéo measure `Net Revenue` vào filter của slicer, chọn is not blank (đã chạy được).

**Ôn code Python cuối ngày**
- `def stats(sql, max_mb=100):` chỉ định nghĩa hàm, chưa chạy query. `max_mb=100` là tham số có giá trị mặc định (gọi `stats(sql, 500)` thì đổi). `return df` đưa kết quả về nơi gọi; thiếu nó thì `df` = `None`, `print(len(df))` báo `TypeError`, còn trần 100 MB và dòng in byte vẫn chạy.
- `QueryJobConfig(dry_run=True, ...)` rồi `client.query(...)`: BigQuery chỉ kiểm tra cú pháp và ước lượng byte, không đọc dữ liệu, không tốn tiền; không cần `job.result()`. Ở `stats` thì `job.result()` chờ job xong rồi lấy kết quả, và phải đứng trước khi đọc byte.

**Điều mình chưa chắc**
- Ngày 29/02 với `EDATE(..., -12)` (chưa thử; dữ liệu hiện chưa rơi vào ngày này).
- `DATEADD(LastData, -1, YEAR)` có cho cùng kết quả với `EDATE` không (chưa so).
- Filter slicer bằng measure có làm slicer chậm hoặc đổi theo bộ lọc khác không.
- Chi phí thật của Refresh Power BI (3 bảng) và của các lần `dbt test` (vẫn chưa đo).

**Cần ôn lại đầu ngày sau:** (1) `LastData` luôn là 22/10/2026 nhờ `REMOVEFILTERS`, không đổi theo slicer; mốc cắt luôn là 22/10/2025; (2) filter ngày của một dòng tháng là tập 31 ngày, các filter trong `CALCULATE` giao nhau; (3) `TOTALYTD` tính lại từ đầu mỗi ô; BLANK trong phép trừ coi như 0; (4) `relationships` tìm khóa fact không có trong dim (không kiểm NULL); `dbt test` không chạm tầng DAX; (5) `def` chỉ định nghĩa, tham số mặc định, thiếu `return` thì `None`.
## Tuần 5 - Ngày 3: thiết kế dashboard trong Power BI

**Ý chính (4 ý cần nhớ)**
- Dashboard trả lời 3 câu hỏi của người xem (doanh thu và lợi nhuận năm nay so cùng kỳ, doanh thu theo tháng, danh mục nào bán nhiều và biên bao nhiêu), không phải càng nhiều biểu đồ càng tốt. Số nào lên dashboard cũng phải khớp một câu SQL độc lập.
- Measure đơn giản vẫn sai âm thầm: `Avg Order Value` ra 61,00 trong khi SQL ra 88,68 (982.813,17 chia 11.083 đơn); không có lỗi đỏ vì DAX chỉ kiểm cú pháp, không kiểm nghĩa. Sai ngay cả khi không bấm gì, nên nguyên nhân không phải interaction. Nghi mẫu số là số dòng thay vì số đơn (suy luận, chưa xem công thức cũ). Phát hiện được nhờ Cell 3 (SQL độc lập), không nhờ bấm tháng.
- Bộ lọc bấm trên biểu đồ làm thu hẹp tập dòng của fact (không ghi đè giá trị). `MAX(order_date)` tính trên tập dòng đã thu hẹp nên thẻ `Data Through` đổi từ 22/10 thành 31/7 khi bấm 2026-07. Sửa: bọc trong `CALCULATE` với `REMOVEFILTERS(dim_date)` và `REMOVEFILTERS(dim_products)`; thêm Edit interactions tắt lọc từ biểu đồ đường lên các thẻ.
- Top N lọc rồi mới sắp xếp, theo measure `Net Revenue` tính trong filter context hiện tại, nên đổi department thì cả danh sách 10 category đổi (không chỉ thứ tự). Tổng 10 category (671.156,85) chỉ bằng khoảng 68,3% thẻ KPI (982.813,17); phải ghi rõ "Top 10" ở tiêu đề.

**2 measure mới** (bảng `fct_net_sales`)

| Measure | Công thức DAX | Tương đương SQL |
|---|---|---|
| Avg Order Value | `DIVIDE([Net Revenue], [Orders])` | `SAFE_DIVIDE(SUM(sale_price), COUNT(DISTINCT order_id))` |
| Data Through | `CALCULATE(MAX(fct_net_sales[order_date]), REMOVEFILTERS(dim_date), REMOVEFILTERS(dim_products))` | `MAX(order_date)` |

**Trang `Overview`**: text box tiêu đề kèm ghi chú dữ liệu mô phỏng và đơn `Complete`; thẻ `Data Through`; slicer `year_number` (kiểu Between 2026 đến 2026) và slicer `department`; 6 thẻ (Net Revenue, Gross Profit, Gross Margin %, Order, Avg Order Value, YoY %); biểu đồ đường `Net Revenue` và `ly` theo `year_month`; biểu đồ cột Top 10 category theo `Net Revenue`; bảng category (Net Revenue, Gross Profit, Gross Margin %).

**Đối chiếu SQL và Power BI** (cùng bản chụp, không Refresh, năm 2026, chưa lọc department)

| | SQL | Power BI |
|---|---|---|
| Net Revenue | 982.813,17 | 982.813,17 |
| Gross Profit | 510.954,59 | 510.954,59 |
| Margin | 0,5199 | 52,0% |
| Orders | 11.083 | 11.083 |
| Avg Order Value | 88,68 | 88,68 (sau khi sửa; trước đó 61,00) |
| Data Through | 2026-10-22 | 22/10/2026 |

- Số ngày có dữ liệu năm 2026: 295 (đủ từ 1/1 đến 22/10). Top 10 category của Cell 2 khớp biểu đồ cột và bảng ở các dòng đã so; Jeans: Men 64.810,90 + Women 43.527,38 = 108.338,28.
- Men + Women: Orders 5.506 + 5.577 = 11.083, doanh thu 513.220,25 + 469.592,92 = 982.813,17. Vậy năm 2026 mỗi đơn chỉ thuộc một department (chưa kiểm các năm khác).
- Chi phí: Cell 2 processed 1,95 MB, billed 20 MB (2 bảng); Cell 3 processed 1,38 MB, billed 10 MB (1 bảng). Power BI Import mode không tốn byte khi tạo biểu đồ, lọc, bấm.

**Chỗ dễ nhầm**
- Số của thẻ đổi khi bấm tháng là hành vi bình thường (cross-filtering), có ở cả measure đúng lẫn sai; không dùng nó để biết measure đúng hay sai.
- Thẻ "ngày dữ liệu cuối" phải dùng `REMOVEFILTERS`, nếu không người xem đọc nhầm là dữ liệu chỉ đến tháng đã bấm.
- Biểu đồ cột Top 10 không phải tổng doanh thu, nhìn dễ tưởng toàn bộ.
- Bảng category mặc định xếp theo bảng chữ cái; bấm tiêu đề cột `Net Revenue` để xếp giảm dần.

**Ôn code cuối ngày**
- `df.T`: xoay dòng thành cột trên máy bạn để dễ đọc (1 dòng × 7 cột thành 7 dòng × 1 cột); không gửi query, không tốn byte; trả DataFrame mới, `df` gốc không đổi.

**Điều mình chưa chắc**
- Công thức cũ của `Avg Order Value` (mẫu số có đúng là số dòng không).
- `YoY %` khi slicer năm kéo thành nhiều năm (slicer đang kiểu Between, chưa thử).
- Số 26 category (bạn nêu, mình chưa kiểm bằng SQL).

**Cần ôn lại đầu ngày sau:** (1) `MAX(order_date)` đổi khi bấm biểu đồ vì bộ lọc thu hẹp tập dòng của fact (không ghi đè); `REMOVEFILTERS` đưa về ngày cuối của cả bảng; (2) *(đề xuất)* sai âm thầm chỉ lộ nhờ đối chiếu SQL độc lập, 61,00 sai cả khi không lọc; (3) *(đề xuất)* Top N lọc rồi sắp xếp theo measure, danh sách đổi theo department, tổng 10 category nhỏ hơn tổng thẻ KPI.

## Tuần 5 - Ngày 4: tối ưu hiệu năng mô hình và báo cáo Power BI

**Ý chính (4 ý cần nhớ)**
- Ẩn cột (Hide) chỉ giấu cột khỏi danh sách trường; dữ liệu vẫn nằm trong bảng Import, quan hệ và measure vẫn dùng được. Bỏ cột ở Power Query (Choose columns) thì cột không được nạp vào mô hình, nên `.pbix` nhẹ hơn; bỏ cột đang được dùng thì quan hệ hoặc measure báo lỗi.
- Performance Analyzer chia thời gian một biểu đồ thành `DAX query`, `Visual display`, `Other`. `DAX query` của mình luôn dưới khoảng 150 ms, nên sửa measure không làm dashboard nhanh hơn đáng kể; thời gian nằm ở vẽ biểu đồ và chờ.
- Hai lượt đo cùng một thao tác lệch nhau hàng nghìn ms (nhiễu đo), lớn hơn mọi khác biệt trước và sau, nên không kết luận được "nhanh hơn". Số đo rõ ràng duy nhất là dung lượng file.
- "Không thấy trong `INFORMATION_SCHEMA.JOBS`" chưa chứng minh "không tốn tiền": Power BI có thể đọc qua đường khác không tạo job truy vấn.

**Số đo** (bản chụp `fct_net_sales` 45.285 dòng, không `dbt run`)

| | Trước | Sau |
|---|---|---|
| `.pbix` | 3.669.950 byte (3,50 MB) | 1.540.766 byte (1,47 MB) |
| Cột `fct_net_sales` | 8 | 5 (bỏ `order_item_id`, `user_id`, `cost`) |
| Cột `dim_products` | 5 | 4 (bỏ `product_name`) |
| KPI năm 2026 | khớp SQL | khớp SQL (982.813,17; 11.083 đơn; 88,68) |

- Số giá trị khác nhau: `order_item_id` 45.285, `order_id` 31.203, `user_id` 27.546, `product_id` 22.840, `cost` 21.071, `gross_profit` 21.079, `sale_price` 3.681, `order_date` 2.670. Ba cột bỏ nằm trong nhóm nhiều giá trị khác nhau mà Power BI không dùng.
- Performance Analyzer: `Table` thường chậm nhất; `Visual display` khoảng 0,1 đến 3,8 giây giữa các lượt.

**Chỗ dễ nhầm**
- Cell xanh không lỗi mà không in gì: `len(df)` bằng 0 là tập rỗng (không có dòng nào khớp), không phải null; vòng `for` chạy 0 lần.
- Dòng thiếu `AS tên` làm BigQuery tự đặt tên `f0_`; giá trị vẫn đúng.
- Cell 5, 5b, 5c không thấy lần Close & Apply; đừng ghi "Refresh miễn phí".

**Ôn code cuối ngày**
- `if not PBIX.exists():` + `return`: kiểm tra file có tồn tại không rồi thoát hàm; bỏ đoạn này thì dòng `PBIX.stat()` nổ lỗi đỏ `FileNotFoundError`. Lỗi đỏ ở đây là không tìm thấy file, không phải sai code.
- `sql = r"""..."""` và `r'\s+'`: `r` trước `"""` (Python) giữ nguyên dấu `\`; `r` trước `'\s+'` (BigQuery) là chuỗi thô phía SQL.

**Điều mình chưa chắc**
- Byte Refresh của Power BI (không thấy trong `JOBS`; kiểm Billing Reports ngày 23/10).
- Bỏ cột có giảm byte đọc từ BigQuery không.
- Chỉ ẩn cột thì `.pbix` đổi không (chưa thí nghiệm).

**Cần ôn lại đầu ngày sau:** (1) ẩn khác bỏ cột; (2) `len(df)` bằng 0 là tập rỗng, vòng `for` chạy 0 lần, cell vẫn xanh; (3) nhiễu đo ms lớn hơn khác biệt trước và sau nên không kết luận tốc độ; (4) "không thấy trong `JOBS`" không có nghĩa là không tốn tiền; (5) `r"""` giữ nguyên `\`.

## Tuần 5 - Ngày 5: khảo sát tuyển dụng, ETL và giấy phép dữ liệu

**Ý chính (4 ý cần nhớ)**
- ETL là Extract (lấy từ nguồn), Transform (làm sạch, đổi kiểu, kiểm tra), Load (nạp vào đích). ELT nạp dữ liệu thô vào warehouse trước rồi biến đổi bằng SQL ngay trong đó. Pipeline thời tiết (Tuần 1) là ETL: biến đổi bằng pandas trước khi nạp. dbt trên BigQuery là ELT: nguồn đã nằm trong BigQuery, dbt chỉ gửi `SELECT` lên để dựng staging và mart.
- Khảo sát 27 tin ở TP.HCM (20 tin BI/Data Analyst, 7 tin Analytics/Data Engineer, lấy từ trang liệt kê, chưa đọc trọn từng JD): nhóm BI/DA có Power BI 17/20, Tableau 9/20, Looker 4/20; dbt (6/7) và BigQuery (4/7) chỉ nằm ở tin kỹ sư; Airflow 3/7; Docker 0. Truy vấn đầu chứa "Power BI" nên con số Power BI bị thổi phồng. Có tin logistics cụ thể (GHN, Tân Cảng, Tiki, tiếp vận, CyberLogitec, Wecare); GHN đòi 2 đến 4 năm kinh nghiệm và ưu tiên người từng làm logistics hoặc e-commerce.
- CC BY-NC-SA 4.0 (giấy phép của bộ Olist trên Kaggle): BY là phải ghi nguồn; NC là không dùng cho mục đích thương mại; SA là sản phẩm phái sinh giữ cùng giấy phép. Hệ quả: dùng để học và portfolio thì phù hợp, nhưng không dùng sản phẩm này cho khách trả tiền, và không đưa dữ liệu hay bảng đã biến đổi lên GitHub. Mình không phải luật sư; dùng portfolio để xin việc là vùng xám.
- Job tự động mà lỗi không lộ ra thì nguy hơn chạy tay. "Chỉ nhìn kết quả xem có lỗi không" chỉ đúng khi lỗi lộ được: kiểm số dòng nạp so với số dòng gửi, `validate`, dòng vàng của dbt, mã thoát 0 hoặc 1. Đã gặp nhiều lỗi âm thầm: test PASS mà số vẫn đổi, vòng `for` chạy 0 lần mà cell vẫn xanh, gõ sai tên model chỉ ra dòng vàng.

**Tiêu chí xong của Project 1 (6 tiêu chí)**
- `dbt test` đạt toàn bộ test của 4 mart (mong đợi PASS=14).
- Mọi thẻ KPI khớp một câu SQL độc lập.
- Star schema: `fct_net_sales` giữa, `dim_products` và `dim_date` nối vào, Single.
- Cầu chì chi phí (`maximum_bytes_billed`) ghi trong README.
- README đủ: mục tiêu, nguồn, kiến trúc, cách chạy lại, hạn chế.
- Repo không có bí mật, `.pbix`, `data/`.

**Tiêu chí thêm cho Project 2**
- (7) Chạy theo lịch không cần can thiệp; mỗi lần chạy có log từng bước (Extract, Transform, Load, `dbt run`, `dbt test`), mã thoát 0 hoặc 1, và một chỗ duy nhất để xem đêm qua OK hay lỗi.
- (8) README ghi nguồn, giấy phép, và nêu rõ không dùng cho khách trả tiền.

**Điều mình chưa chắc**
- Thư mục `D:\BI\Dataset` (5 file CSV và `Template.png`) có phải bộ Olist không: tên file và dung lượng (ba file chỉ 143, 628, 225 byte) không giống điều mình nhớ về Olist. Chưa mở xem.
- Olist có phải dữ liệu đóng băng không (nếu vậy thì "cập nhật tự động" phải mô phỏng bằng cách nạp từng khối thời gian).
- Nhiều tin ghi ETL: họ muốn mình viết pipeline hay chỉ dùng dữ liệu đã qua ETL (chưa đọc trọn JD).
- GitHub Actions xác thực với BigQuery thế nào khi không dùng file khóa (chưa tìm hiểu).

**Cần ôn lại đầu ngày sau:** (1) ETL biến đổi trước khi nạp, ELT nạp thô rồi biến đổi trong warehouse; pipeline thời tiết là ETL, dbt là ELT; (2) CC BY-NC-SA: BY ghi nguồn, NC không thương mại, SA cùng giấy phép; không đưa dữ liệu lên GitHub; (3) số đếm Power BI bị thổi phồng vì truy vấn đầu chứa "Power BI"; (4) lỗi không lộ ra thì job tự động nguy hơn chạy tay.

## Tuần 5 - Ngày 6: đóng Project 1 và xác nhận dữ liệu Project 2

**Ý chính (4 ý cần nhớ)**
- Project 1 đạt đủ 6 tiêu chí: `dbt test --select dim_products fct_net_sales fct_net_sales_inc dim_date` ra `PASS=14 WARN=0 ERROR=0 TOTAL=14` (24,72 giây); thẻ KPI khớp SQL; star schema 2 quan hệ Single; cầu chì `maximum_bytes_billed` ghi trong README; README đủ mục; repo không có bí mật, `.pbix`, `data/`.
- Quét bí mật phải xong trước khi push, không phải sau. Lệnh quét file đang được Git theo dõi: `git grep -n -i -E '@gmail|AIza|private_key|api_key'` (dấu nháy đơn trong PowerShell). Kết quả: 2 dòng, cả hai an toàn (`.env.example` chữ giữ chỗ, `Day4.ipynb` đọc khóa bằng `os.getenv`). Lệnh chỉ quét bản hiện tại, không quét lịch sử commit.
- Billing Overview ngày 24/10/2026: tổng chi phí ₫0, tín dụng dùng thử còn nguyên, còn 73 ngày (hết 06/01/2027). Trang ghi chi phí có thể trễ hơn 24 giờ, nên chưa chứng minh Refresh Power BI miễn phí; trong README chỉ ghi "chưa đo".
- `D:\BI\Dataset` không phải Olist. Bộ Olist nằm ở `D:\BI\projects\ai-logistics\data\olist` (9 file: customers, geolocation, order_items, order_payments, order_reviews, orders, products, sellers, product_category_name_translation). Mở bằng VS Code, không mở bằng Excel (CSV đang liên kết với Excel, lưu lại có thể làm hỏng định dạng như mã zip).

**Đã làm**
- README: chuyển `### Architecture` và `### Data model (diagram)` (Mermaid) từ dưới `## Lưu ý an toàn` vào trong `## Project 1`; mục Screenshots dùng đúng tên file `Doc/Dashboard.png`, `Doc/PowerBI_Model.png`, `Doc/dbt_lineage.png`; thêm dòng về chi phí Refresh chưa đo vào Limitations. Giữ README lẫn tiếng Việt (phần thời tiết) và tiếng Anh (Project 1) đến Tuần 8.
- `Doc/Definition_of_done.md`: tích đủ 6 mục.
- Kiểm tra repo: `git ls-files bi_dbt/models` đủ file; lệnh tìm `pbix|.env|profiles|.csv|.parquet|data/|logs/` không in dòng nào. Ba file thử `Ghi_chu.txt`, `test_bq.ipynb`, `viewtable.ipynb` vẫn nằm trong repo (đã quyết giữ nguyên).

**Chỗ dễ nhầm**
- PowerShell không hiểu `\"` để thoát dấu ngoặc kép: lệnh treo ở dấu `>>`. Thoát bằng Ctrl+C và dùng dấu nháy đơn.
- Dấu chấm `●` trên tab VS Code nghĩa là file chưa lưu; `git add` lúc đó lấy bản cũ. Ctrl+S trước.
- Lineage chỉ hiện `fct_net_sales` và hai staging, không hiện `dim_products` và `dim_date`, vì `fct_net_sales` không phụ thuộc vào hai bảng đó.

**Ôn cuối ngày** (3 câu Python, 3 câu nội dung)
- `for _, row in df.iterrows()` khi `len(df)` là 0: vòng chạy **0 lần**, cell vẫn xanh; `0` là tập rỗng, không phải null.
- `def stats(sql, max_mb=100)`: Cell chứa `def` chỉ định nghĩa, query chưa gửi cho đến khi gọi `stats(sql)`; `max_mb=100` là tham số mặc định (gọi `stats(sql, 500)` thì đổi); biến trong hàm mất khi hàm kết thúc, `return df` đưa ra ngoài, thiếu thì `df` là `None`.
- `r"""...r'\s+'..."""`: chữ `r` ngoài cùng là của Python (giữ nguyên `\`); chữ `r` trong `'...'` là của BigQuery (chuỗi thô phía SQL).
- `PASS=14`: kiểm cấu trúc (`unique`, `not_null`, `accepted_values`, `relationships`), không đối chiếu giá trị với nguồn, không chạm tầng DAX; `relationships` tìm khóa của fact không có trong dimension, không phải NULL.
- `CALCULATE([Net Revenue], dim_products[department] = "Men")` ở dòng Women hiện số của Men; filter cùng cột `department` bị ghi đè, filter năm từ `dim_date` vẫn đi qua.
- ETL: biến đổi trước khi nạp (pipeline thời tiết, pandas). ELT: dữ liệu đã nằm trong BigQuery, dbt chỉ gửi `SELECT` lên đó.

**Điều mình chưa chắc**
- Nội dung `D:\BI\Dataset` (5 file nhỏ, ba file 143, 628 và 225 byte).
- Tên cột thật của 9 file Olist, và Olist có phải dữ liệu đóng băng không (chưa mở).
- Lịch sử commit có sạch bí mật không (chỉ quét bản hiện tại).
- Chi phí thật của Refresh Power BI và của `dbt test` (Billing chưa hiện).

**Cần ôn lại đầu ngày sau:** (1) `for` với `df` rỗng chạy 0 lần; (2) `def` chỉ định nghĩa, biến cục bộ mất, `return` đưa ra ngoài, thiếu `return` thì `None`; (3) `r` ngoài là Python, `r` trong SQL là BigQuery; (4) `relationships` tìm khóa mồ côi của fact, không phải NULL; (5) `CALCULATE` ghi đè filter cùng cột, filter cột khác vẫn đi qua.

## Tuần 6 - Ngày 1: tạo repo olist-bi-project

**Ý chính (4 ý cần nhớ)**
- `.env` chứa giá trị thật của máy mình (đường dẫn, sau này có thể là khóa), bị `.gitignore` chặn nên không lên GitHub. `.env.example` chỉ có tên biến, có commit, để người clone biết cần cấu hình gì. Repo công khai nên không bao giờ commit `.env`.
- `.gitignore` phải có luật chặn trước khi có file dữ liệu đầu tiên, vì file đã commit rồi thì thêm vào `.gitignore` không gỡ được khỏi lịch sử. `git check-ignore -v <đường dẫn>` in ra dòng luật đang chặn file đó; không in gì nghĩa là file chưa bị chặn.
- Quét bí mật phải xong trước `git push`: `git grep --cached -n -i -E '@gmail|AIza|private_key|api_key'` (dấu nháy đơn trong PowerShell) quét các file đã `git add`; không in dòng nào là sạch. Lệnh chỉ quét bản đang chuẩn bị commit, không quét lịch sử.
- README của Project 2 ghi ngay từ đầu nguồn dữ liệu, giấy phép CC BY-NC-SA 4.0, dữ liệu không nằm trong repo, và dự án không dùng cho khách trả tiền.

**Đã làm**
- Repo `olist-bi-project` (Public) trên GitHub, clone về `D:\BI\projects\olist-bi-project`; khối luật cuối `.gitignore`; `.env`, `.env.example`, `README.md`; notebook `Notebook/Week01/Day1.ipynb`.
- Notebook đọc `OLIST_DIR` từ `.env`, liệt kê file `.csv` và đọc tiêu đề từng file. 9 file, tổng khoảng 120 MB (lớn nhất `geolocation` 58,44 MB; nhỏ nhất `product_category_name_translation` khoảng 0 MB). Số cột: customers 5, geolocation 5, order_items 7, order_payments 5, order_reviews 7, orders 8, products 9, sellers 4, translation 2. Chưa thấy trọn tên cột của `orders` (cột thứ 8) và `products` (cột thứ 9) vì ảnh bị cắt.

**Chỗ dễ nhầm**
- Thư mục tên `Notebook/` (viết hoa) khác `notebooks/` trong hướng dẫn; gõ `git add` theo tên thật.
- `check-ignore` có thể hiện luật của khối mình thêm thay vì luật có sẵn của mẫu Python; miễn là có in dòng thì file đã bị chặn.
- Dấu `●` trên tab VS Code nghĩa là file chưa lưu; `git add` lúc đó lấy bản cũ.


- **Ôn cuối ngày**: 6 câu (3 Python, 3 nội dung). Đúng ý chính: `nrows=0` chỉ đọc tiêu đề; `files` rỗng thì vòng `for` chạy 0 lần; `.gitignore` thêm sau không gỡ được file đã lên GitHub. Cần ôn: `.tolist()` đổi sang list; mốc quyết định là `git add`/`commit`, lịch sử vẫn giữ file; `print(len(files))` đứng trước vòng `for` để bắt trường hợp rỗng; `git grep --cached` không quét lịch sử và chỉ quét 4 mẫu (không liên quan `.env`); `os.getenv` đọc biến môi trường, `load_dotenv` mới đọc file `.env`, `""` là giá trị mặc định; CC BY-NC-SA: BY ghi nguồn, NC không thương mại, SA cùng giấy phép; không đưa dữ liệu lên GitHub là quyết định thận trọng.

**Điều mình chưa chắc**
- Khóa và grain thật của `order_items` (cặp `order_id`, `order_item_id`?), `order_payments` (cặp `order_id`, `payment_sequential`?), `order_reviews` (`review_id` có duy nhất không?), `geolocation` (một dòng là gì?): chưa kiểm bằng SQL.
- `customer_id` gắn theo đơn hay theo người, và vai trò của `customer_unique_id` (mình nhớ là theo đơn, chưa kiểm trên dữ liệu này).
- Cột thứ 8 của `orders` và cột thứ 9 của `products` (ảnh bị cắt).
- Olist có phải dữ liệu đóng băng không (chia khối thời gian thế nào để mô phỏng cập nhật tự động).

**Cần ôn lại đầu ngày sau:** (1) `.env` khác `.env.example` (cái nào commit, cái nào không, vì sao); (2) `check-ignore -v` in dòng luật, không in gì là chưa chặn; (3) quét bí mật trước push, chỉ quét bản hiện tại; (4) `pd.read_csv(f, nrows=0)` chỉ đọc tiêu đề; (5) `load_dotenv` đọc file `.env` và nạp vào biến môi trường, `os.getenv` chỉ đọc biến đã được nạp; (6) CC BY-NC-SA: BY ghi nguồn, NC không thương mại, SA giữ cùng giấy phép.

## Tuần 6 - Ngày 2: khám phá 9 file Olist (tên cột, grain, khóa nối, khoảng ngày)

**Ý chính (4 ý cần nhớ)**
- Phải kiểm grain trước khi nối: nối sang bảng có nhiều dòng cho một khóa thì dòng bên trái bị nhân lên, SUM và COUNT cộng lặp mà không có lỗi nào. `geolocation` 1.000.163 dòng nhưng chỉ khoảng 19.015 mã zip khác nhau, nên một dòng không phải một mã zip; nối thẳng theo zip là nhân dòng (khách A có 1 dòng, zip có 3 dòng thì ra 3 dòng, 100 thành 300).
- Khóa mồ côi (có ở bảng con, không có ở bảng cha) khác NULL (không có khóa). `products.product_category_name` sang `translation`: NULL 610 (nằm ngay trong `products`) và mồ côi 13 (số dòng sản phẩm, không phải số tên category), tổng 623 sản phẩm không có tên tiếng Anh. `join` thường làm 623 sản phẩm biến mất âm thầm; `left join` giữ lại và cột tên tiếng Anh là NULL.
- Dữ liệu Olist là bản chụp lịch sử, đơn từ 2016-09-04 đến 2018-10-17, không tự cập nhật. "Cập nhật tự động" của Project 2 sẽ mô phỏng bằng cách chia theo `orders.order_purchase_timestamp` (từng tháng) và nạp thêm một khối mỗi lần chạy; `items`, `payments`, `reviews` đi theo `order_id`. README phải ghi rõ đây là mô phỏng.
- `pd.to_datetime(..., errors="coerce")` đổi ngày hỏng thành `NaT` thay vì dừng cell; `ts.isna().sum()` đếm số ngày hỏng (hôm nay là 0).

**Đã làm** (notebook đọc dữ liệu bằng pandas, không đụng BigQuery nên 0 byte, không tốn tiền)

| Bảng | Số dòng | Khóa đã kiểm | Kết quả |
|---|---|---|---|
| `customers` | 99.441 | `customer_id` | trùng 0 |
| `orders` | 99.441 | `order_id` | trùng 0 |
| `items` | 112.650 | `order_id`, `order_item_id` | trùng 0 |
| `payments` | 103.886 | `order_id`, `payment_sequential` | trùng 0 |
| `reviews` | 99.224 | `review_id` | trùng 814 |
| `reviews` | 99.224 | `review_id`, `order_id` | trùng 0 |
| `products` | 32.951 | `product_id` | trùng 0 |
| `sellers` | 3.095 | `seller_id` | trùng 0 |
| `translation` | 71 | `product_category_name` | trùng 0 |
| `geolocation` | 1.000.163 | `geolocation_zip_code_prefix` | trùng 981.148 |

- Khóa nối (con tìm cha), mồ côi 0 và NULL 0: `items.order_id` sang `orders`, `items.product_id` sang `products`, `items.seller_id` sang `sellers`, `orders.customer_id` sang `customers`, `payments.order_id` sang `orders`, `reviews.order_id` sang `orders`. Ngoại lệ: `products.product_category_name` sang `translation` (NULL 610, mồ côi 13).
- Ngày đặt hàng: 0 ngày không đọc được; đơn thưa ở cuối 2016 (2016-09: 4, 2016-10: 324, 2016-12: 1, không có 2016-11), bắt đầu dày từ 2017-01 (800), đỉnh 2017-11 (7.544), quanh 6.700 đến 7.200 trong 2018; 2018-10 là tháng dở (ngày cuối 17/10).

**Chỗ dễ nhầm**
- `review_id` không duy nhất (814 trùng); khóa duy nhất tốt nhất mình tìm thấy là cặp (`review_id`, `order_id`). Chưa biết vì sao có `review_id` lặp.
- Phép kiểm mồ côi chỉ đi một chiều (con tìm cha); đơn không có mặt hàng nào chưa kiểm.
- Output Cell 5 bị cắt: chỉ thấy đuôi `processing` 301, `created` 5, `approved` 2; danh sách trạng thái đầy đủ và các tháng 2018-06 đến 2018-10 chưa xem.

**Ôn cuối ngày** (6 câu: 3 Python, 3 nội dung)
- Câu 1: `found_in_parent = child_not_null.isin(parent_values)` ra dãy True/False dài bằng số dòng bảng con; đúng ý chính, thiếu ý kiểu và độ dài. Câu 2: nhầm chỗ 610 (NULL trong `products`), 13 là mồ côi; hiểu đúng lý do báo cáo sai âm thầm. Câu 3: `missing_cols` rỗng thì `print` và `continue` bị bỏ qua, nhưng code vẫn chạy tiếp Bước 3 và in kết quả. Câu 4: chưa biết, sau ví dụ khách A thì đúng. Câu 5: đúng (`coerce` đổi ngày hỏng thành `NaT`, `isna().sum()` đếm). Câu 6: chưa biết; chọn đúng cột chia theo thời gian, nhưng gọi nhầm tên là `order_date` (đúng là `order_purchase_timestamp`).

**Điều mình chưa chắc**
- Tên đầy đủ các cột còn lại của 9 bảng (chỉ chắc các cột đã chạy qua Cell 3, 4, 5).
- `customer_unique_id` có lặp qua nhiều `customer_id` không (một người nhiều đơn), chưa kiểm.
- Danh sách 13 sản phẩm mồ côi thuộc mấy category khác nhau.
- Cách chia `items`, `payments`, `reviews` theo khối tháng cho khớp `orders`; `reviews` có chữ xuống dòng trong ô khi nạp CSV, mã zip giữ số 0 đầu, encoding: chưa thử.
- Kiểu cột ở `olist_raw`: khai báo đủ kiểu hay nạp toàn bộ STRING rồi ép kiểu trong dbt staging (bạn chưa chốt).

**Cần ôn lại đầu ngày sau:** (1) nối sang bảng nhiều dòng cho một khóa thì dòng bị nhân lên, kiểm số dòng trước và sau khi nối; (2) NULL (không có khóa) khác mồ côi (có khóa nhưng bảng cha không có), `left join` để không mất dòng; (3) `isin` trả dãy True/False dài bằng bảng con; (4) code chạy tiếp Bước 3 khi `missing_cols` rỗng; (5) tên cột chia thời gian là `order_purchase_timestamp`, dữ liệu là bản chụp 2016 đến 2018 nên cập nhật tự động chỉ là mô phỏng.

## Tuần 6 - Ngày 3: nạp translation vào olist_raw

**Ý chính (4 ý cần nhớ)**
- Raw toàn STRING, ép kiểu ở dbt staging bằng `SAFE_CAST` (ELT). Lý do: giữ số 0 đầu của mã zip, ngày hỏng không làm cả load job thất bại, raw giữ nguyên dữ liệu gốc. Đánh đổi: staging phải ép kiểu từng cột và đếm NULL sau khi ép.
- Load job đọc file trên máy rồi ghi vào bảng, không gửi SQL nên không tính byte truy vấn. `LoadJobConfig` chỉ là cấu hình; việc nạp xảy ra khi đưa nó vào `client.load_table_from_file`.
- `skip_leading_rows=1` bỏ dòng tiêu đề; `WRITE_TRUNCATE` cho chạy lại vẫn 71 dòng (idempotent); `WRITE_APPEND` chạy hai lần ra 142 dòng. Thiếu `skip_leading_rows` với cột STRING thì tiêu đề lẫn vào dữ liệu mà không báo lỗi (72 dòng).
- Đối chiếu số dòng bằng nguồn độc lập: số đếm từ file CSV so với `t.num_rows` hoặc `COUNT(*)`. `job.output_rows` cũng là số phía BigQuery báo lại.

**Đã làm** (`Notebook/Week03/Day3.ipynb`)
- Cell 1: `client`, `mb`, `stats`; 9 file CSV, location US. Cell 2: dataset `olist_raw` (US). Cell 3: hàm `load_csv_as_string(csv_path, table_name)`, nạp 71 dòng, 2 cột. Cell 4: `num_rows` 71, `COUNT(*)` 71, 71 category khác nhau, hai cột STRING; billed 10 MB (processed 0,0 MB).

**Chỗ dễ nhầm**
- `with open(csv_path, "rb") as f:` mở file đọc byte thô và tự đóng khi khối thụt vào xong; `job.result()` đứng ngoài khối chỉ chờ job xong.
- `table_name` là tham số của hàm, nhận giá trị ở dòng gọi hàm.
- `len(df)` bằng 1 vì `df` là kết quả của `SELECT COUNT(*)`; số dòng của bảng là ô `so_dong`.
- NULL (ô category trống, 610) khác mồ côi (có tên nhưng `translation` không có, 13): `join` thường làm cả 623 sản phẩm mất âm thầm, `left join` giữ lại.

**Điều mình chưa chắc**
- `reviews` (chữ xuống dòng trong ô) và `geolocation` (mã zip, 1 triệu dòng) nạp có ổn không.
- Đóng file trước khi `job.result()` có ảnh hưởng gì không (mình tin là không, chưa kiểm tài liệu).

**Cần ôn lại đầu ngày sau:** (1) `job.result()` chờ, không gán; (2) NULL khác mồ côi; (3) lý do raw toàn STRING và việc `SAFE_CAST` ở staging; (4) `WRITE_APPEND` hai lần ra 142; (5) `len(df)` khác số dòng bảng, nguồn độc lập là file CSV.

## Tuần 6 - Ngày 4: nạp 8 bảng Olist còn lại vào olist_raw

**Ý chính (4 ý cần nhớ)**
- Mọi bảng raw đều nạp toàn STRING để BigQuery không tự đổi dữ liệu (ví dụ mất số 0 đầu của zip) và load job không thất bại vì kiểu; ép kiểu dời sang staging bằng `SAFE_CAST`. Cell 5b cho thấy zip ở cả ba bảng đều dài 5 ký tự, nên raw giữ nguyên.
- Đối chiếu số dòng cần nguồn đứng ngoài BigQuery: `n_job` (`job.output_rows`) và `n_tbl` (`num_rows`) đều do BigQuery báo, cùng sai thì vẫn bằng nhau; `n_csv` đếm từ file CSV là nguồn ngoài. `n_csv` và số của Ngày 2 đều đếm bằng pandas nên cùng sai nếu pandas đọc sai.
- Khối `try/except` trong vòng `for` giúp một bảng lỗi không dừng cả vòng, nhưng cell vẫn xanh nên phải đọc output tìm chữ `LỖI` và dòng `Bảng có vấn đề`; bảng lỗi để lại bản cũ trên BigQuery mà không có dấu hiệu.
- Khi nối `products` với `translation`: NULL (610 ô trống) khác mồ côi (13 dòng có tên nhưng `translation` không có). `join` thường làm mất 623 sản phẩm mà không có lỗi đỏ; `left join` giữ lại với tên tiếng Anh NULL, cần xử lý ở staging.

**Đã làm** (`Notebook/Week04/Day4.ipynb`)

| Bảng raw | Số dòng | Số cột |
|---|---|---|
| `customers` | 99.441 | 5 |
| `geolocation` | 1.000.163 | 5 |
| `order_items` | 112.650 | 7 |
| `order_payments` | 103.886 | 5 |
| `order_reviews` | 99.224 | 7 |
| `orders` | 99.441 | 8 |
| `products` | 32.951 | 9 |
| `sellers` | 3.095 | 4 |

- Cell 3 chạy hai lần: lần hai số dòng không đổi (`WRITE_TRUNCATE`, idempotent). Lần chạy thứ hai mất 1 phút 42 giây (`geolocation` lâu nhất).
- Cell 4: cột thứ 8 của `orders` là `order_estimated_delivery_date`, cột thứ 9 của `products` là `product_width_cm`; `products` có hai cột sai chính tả từ nguồn (`product_name_lenght`, `product_description_lenght`).
- Cell 5: `order_reviews` có 3.852 ô comment chứa chữ xuống dòng, nạp nguyên vẹn (dòng không bị tách); 58.247 ô `review_comment_message` là NULL (khoảng 58,7%), 0 chuỗi rỗng.
- Cell 5b: `customers`, `sellers`, `geolocation` chỉ có zip dài 5. Billed 30 MB cho ba bảng, 10 MB cho một bảng.

**Chỗ dễ nhầm**
- `schemaField` (chữ `s` thường) thay vì `SchemaField`: lỗi nổ trước khi load job gửi đi, cả 8 bảng in `LỖI`, cell vẫn xanh.
- `len(df)` ở Cell 5 là 1 (kết quả `COUNT(*)` là một dòng); số 99.224 là giá trị trong ô `so_dong`.
- Dòng tiêu đề được bỏ bằng `skip_leading_rows=1`, nên bảng có 99.224 dòng dữ liệu, không phải 99.225.
- `n_tbl` là `num_rows` của bảng BigQuery, không phải của pandas; pandas chỉ đếm `n_csv`.

**Ôn cuối ngày** (3 câu Python, 3 câu nội dung)
- `job.result()` chờ job xong; bỏ nó thì `output_rows` thường là `None` (chưa thử), không phải lỗi đỏ, rồi dòng `print` có `{n_job:>9,}` nổ lỗi, `except` in `LỖI`.
- Raw toàn STRING: ví dụ mất số 0 đầu của zip; nếu cả ba cột cùng mất số 0 thì vẫn nối được nhưng dữ liệu đã đổi âm thầm; thiếu lý do load job không thất bại vì kiểu, và `SAFE_CAST` ở staging.
- `try/except` trong Cell 3: bảng lỗi in `LỖI`, vào `problems`, vòng `for` đi tiếp, cell không đỏ, bảng cũ còn lại; `print(len(TABLES))` là số bảng dự định, bắt dictionary rỗng.

**Điều mình chưa chắc**
- Ô trống ở các cột khác thành NULL hay chuỗi rỗng (mới kiểm `review_comment_message`).
- Có zip nào bắt đầu bằng `'0'` không (mới suy ra từ độ dài).
- Bỏ `job.result()` thì `output_rows` có thật sự là `None` không.
- `review_id` trùng 814 dòng ở `order_reviews`: vì sao lặp (chưa xem).

**Cần ôn lại đầu ngày sau:** (1) `job.result()` chờ job xong, đọc kết quả quá sớm thường ra `None`; (2) `len(df)` là số dòng kết quả SQL, số dòng của bảng là giá trị trong ô `so_dong`; (3) `n_job` và `n_tbl` cùng phía BigQuery, cần nguồn ngoài như `n_csv`; (4) `except` nuốt lỗi, bảng cũ còn lại, đọc `problems`; (5) `join` thường làm mất 623 sản phẩm, `left join` giữ lại nhưng tên NULL.

## Tuần 6 - Ngày 5: dbt cho Project 2 và staging orders

**Ý chính (4 ý cần nhớ)**
- Project dbt của Project 2 là `olist_dbt/` trong repo `olist-bi-project`, ghi vào dataset `olist_dbt_dev` (US), tách khỏi `dbt_dev` của Project 1. Mọi query dbt có `maximum_bytes_billed: 1000000000` trong `profiles.yml` (nằm ngoài repo, không commit).
- Staging chỉ đổi tên cột và ép kiểu bằng `SAFE_CAST` (ELT, raw toàn STRING). `SAFE_CAST` không báo lỗi mà đổi ô hỏng thành NULL, nên mỗi lần ép kiểu một cột mới phải so số NULL trước và sau ép trên bảng raw. Hai số bằng nhau thì ép kiểu không làm hỏng ô nào; `cast_null` lớn hơn `raw_null` thì phần chênh là ô có giá trị nhưng không ép được.
- `dbt test` PASS=2 (`unique`, `not_null` trên `order_id`) chỉ chứng minh khóa không trùng và không NULL. Test không bắt được ô ngày bị ép thành NULL, giá trị `order_status` lạ, `customer_id` mồ côi, hay số dòng lệch so với file CSV.
- `.gitignore`: luật không có dấu `/` ở đầu (`olist/`) khớp thư mục cùng tên ở mọi cấp, nên chặn nhầm `olist_dbt/models/staging/olist/`. `/olist/` chỉ chặn thư mục `olist` ở gốc repo. `git check-ignore -v <đường dẫn>` in ra dòng luật đang chặn file; không in gì là file không bị chặn.

**Đã làm**
- `dbt init olist_dbt` (adapter `bigquery`, `oauth`, project `bq-learning-510104`, dataset `olist_dbt_dev`, location US, threads 4); thêm `maximum_bytes_billed` vào `profiles.yml`; xóa `models/example/`; `dbt_project.yml` đặt `staging` là `view`, `marts` là `table`.
- `models/staging/olist/`: `_olist__sources.yml` (source `olist`, 9 bảng của `olist_raw`), `stg_olist__orders.sql` (view, `SAFE_CAST` 5 cột ngày sang TIMESTAMP, đổi tên thành `purchased_at`, `approved_at`, `delivered_to_carrier_at`, `delivered_to_customer_at`, `estimated_delivery_at`), `_olist__models.yml` (mô tả và 2 test trên `order_id`).
- `dbt test --select stg_olist__orders`: `Found 1 model, 2 data tests, 9 sources, 561 macros`, `PASS=2 TOTAL=2` (8,25 giây).

**Đối chiếu (notebook `Notebook/Week01/Day05.ipynb`)**

| Kiểm tra | Kết quả |
|---|---|
| NULL trước và sau `SAFE_CAST` (purchased, approved, carrier, customer, estimated) | 0/0, 160/160, 1.783/1.783, 2.965/2.965, 0/0 |
| View staging | 99.441 dòng = 99.441 `order_id` duy nhất, ngày 2016-09-04 đến 2018-10-17, `purchased_at` NULL 0 |
| `order_status` (8 giá trị) | delivered 96.478, shipped 1.107, canceled 625, unavailable 609, invoiced 314, processing 301, created 5, approved 2 (tổng 99.441) |

- Chi phí: Cell 2 processed 9,86 MB, Cell 3 processed 5,22 MB, Cell 4 processed 1,04 MB; cả ba billed 10 MB. `dbt run` view là 0 processed.

**Chỗ dễ nhầm**
- Dòng vàng `Configuration paths exist ... models.olist_dbt.marts`: không phải lỗi, do khai báo `marts` trong `dbt_project.yml` khi chưa có thư mục `models/marts/`.
- Anaconda Prompt là `cmd`: lệnh `git grep` phải dùng dấu nháy kép (nháy đơn chỉ đúng trong PowerShell), nếu không `|` bị hiểu là pipe và lệnh báo lỗi.
- `git grep --cached` chỉ quét file đã `git add`; quét trước khi add thì không in gì và không có giá trị. Sau khi đã push thì dùng `git grep ... HEAD`.
- Lần này push trước khi quét xong; từ nay thứ tự là add, quét, commit, push.

**Ôn cuối ngày** (4 câu: 2 Python, 2 nội dung)
- `len(df)` ở Cell 4 là 8: số dòng của kết quả `GROUP BY`, tức số trạng thái; không phải số dòng bảng `orders` (99.441). Thứ tự dòng do `ORDER BY` quyết định, không phải do con số 8.
- Cell 2: hai số NULL bằng nhau nghĩa là `SAFE_CAST` không làm hỏng ô nào; nếu `cast_null` lớn hơn thì phần chênh là ô có giá trị nhưng không ép được. Đúng.
- `check` là dry run (chỉ ước lượng, không chạy thật, không tốn tiền); `stats` chạy thật với trần `maximum_bytes_billed`. `processed` 9,86 MB nhưng `billed` 10,0 MB vì mức tối thiểu 10 MB. Đúng.
- `dbt test` PASS=2 chỉ chứng minh `order_id` không trùng và không NULL; không bắt được ô ngày bị ép thành NULL, giá trị lạ hay khóa mồ côi. Ý chính đúng; ví dụ cần gắn với cột đã được test.

**Điều mình chưa chắc**
- Các NULL ở `delivered_to_carrier_at` (1.783) và `delivered_to_customer_at` (2.965) có khớp với các trạng thái chưa giao hay không (chưa kiểm bằng SQL).
- Chi phí thật của `dbt test` (chưa đo bằng `INFORMATION_SCHEMA.JOBS`).

**Cần ôn lại đầu ngày sau:** (1) `len(df)` là số dòng kết quả SQL, không phải số dòng bảng; (2) `SAFE_CAST` đổi ô hỏng thành NULL, nên so NULL trước và sau; (3) test `unique` và `not_null` chỉ kiểm cột được khai báo, không đối chiếu nguồn; (4) `.gitignore` không có dấu `/` đầu thì khớp ở mọi cấp; (5) thứ tự add, quét bí mật, commit, push.