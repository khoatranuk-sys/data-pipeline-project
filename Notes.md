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