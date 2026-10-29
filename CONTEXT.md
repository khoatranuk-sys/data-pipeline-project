# Ngữ cảnh học tập (dán file này vào đầu mỗi cuộc trò chuyện mới)

> Cập nhật lần cuối: 24/10/2026. ...
> Repo này công khai: không ghi mật khẩu, API key, token, email cá nhân hay dữ liệu khách hàng thật.

## 1. Mục tiêu
- **BI là chính**, data engineering (DE) là phụ.
- Cần biết cloud data platform và pipeline dữ liệu vì các vị trí BI hiện nay yêu cầu.
- Có thể làm freelance BI sau khi xong lộ trình (dashboard, báo cáo tự động cho doanh nghiệp nhỏ).
- Thời gian học: khoảng 8 giờ/ngày, lộ trình 8 tuần + 2 tuần "Project thành thạo" (Tuần 9-10, dữ liệu khác Olist, làm từ đầu). Hướng DE (Docker, Airflow, Terraform, Spark) hoãn, chỉ học khi gặp việc yêu cầu. Ứng tuyển bắt đầu sau Tuần 10.

## 2. Trình độ hiện tại
- SQL: vững.
- Python: cơ bản (đang quen dần với pandas; hiểu pandas dễ hơn khi đối chiếu với SQL).
- Mới học: mô hình hóa dữ liệu, BigQuery, Git/GitHub, gọi API bằng Python.

## 3. Công nghệ đã chọn
- **Cloud warehouse**: BigQuery (đã chọn, không học Snowflake ở giai đoạn này).
- **Biến đổi dữ liệu**: dbt Core (cài ở Tuần 3 Ngày 2: `dbt-core` 1.12.5, `dbt-bigquery` 1.12.1).
- **Kèm Data Studio (tên mới của Looker Studio từ tháng 4/2026; đổi giao diện sang tiếng Anh bằng `https://datastudio.google.com/?hl=en`) để có dashboard sớm.
- **Ưu tiên thấp (để sau)**: Airflow, Docker, Spark, Terraform. Với BI, scheduled query và lịch làm mới của công cụ BI thường là đủ.

## 4. Môi trường trên máy
- Windows, VS Code (dùng cả notebook `.ipynb` và script `.py`).
- Anaconda, môi trường `bi` (Python 3.11). Mỗi lần làm việc: `conda activate bi`, trong VS Code chọn interpreter/kernel `bi`. Đã kiểm tra có sẵn `requests`, `pandas`, `pyarrow`.
- Thư mục repo trên máy: `D:\BI\projects\data-pipeline-project`. Vào bằng Anaconda Prompt: `cd /d "D:\BI\projects\data-pipeline-project"` rồi `code .` (phải có `/d` vì repo nằm ổ D:).
- gcloud CLI đã cài và xác thực (`gcloud auth application-default login`).
- Git đã cài, cấu hình `user.email` bằng email noreply của GitHub.
- Repo GitHub: `data-pipeline-project` (Public), tài khoản `khoatranuk-sys`.
- Google Cloud project: `bq-learning-510104`, location dữ liệu là **US**, đã gắn billing (tài khoản Free Trial, tiền tệ VND, hết hạn 06/01/2027); không còn là sandbox.
- Theo dõi tiến độ bằng file Excel checklist (`lo_trinh_BI_checklist.xlsx`).
- Cấu trúc repo thực tế (tên thư mục viết hoa): `SQL/Day 2/` (file SQL và notebook Ngày 2), `Python/Day 3/` (notebook `Day3.ipynb`), `Doc/` (ảnh sơ đồ), `Notes.md` (ghi chú các ngày), `CONTEXT.md`, `data/` (file dữ liệu tạo ra khi chạy code, **không commit**, nằm trong `.gitignore`).
- Cách chạy query trong notebook VS Code: hai hàm dùng chung `check(sql)` (dry run, chỉ in số MB sẽ quét) và `run(sql, max_mb=100)` (chạy thật, giới hạn `maximum_bytes_billed`). Mỗi truy vấn một cell: gán `sql`, chạy `check`, thấy nhỏ rồi mới chạy `df = run(sql)`.
- Từ Tuần 2 (notebook mới phải định nghĩa lại ở `# Cell 1`): `client` (project, location US), `mb(n)` (đổi byte sang MB, trả `None` nếu `n` là `None` để lỗi đọc quá sớm lộ ra), `check(sql)` (dry run, tắt cache), `stats(sql, max_mb=100)` (chạy thật, tắt cache, đặt `maximum_bytes_billed`, `job.result().to_dataframe()`, in processed và billed, trả DataFrame). Trước khi lặp qua một DataFrame, in `len(df)`: bảng rỗng thì vòng `for` im lặng chạy 0 lần.
- Notebook gọi API (Ngày 3) lưu file ra `Path("../../data")` (notebook nằm ở `Python/Day 3/`, lùi hai cấp ra gốc repo).
- Từ Ngày 4: thêm `Python/Day 4/` (notebook `Day4.ipynb`), `.env` (khóa giả để tập, **không commit**, bị `.gitignore` chặn ở dòng 151) và `.env.example` (file mẫu, có commit). Dataset `bq-learning-510104.raw` (US) chứa dữ liệu thô từ API.
- Terminal VS Code (PowerShell) dùng Python của `base`, không phải `bi`; `conda activate bi` trong PowerShell không có tác dụng. Kernel notebook mới là môi trường `bi`, nên cài thư viện bằng `%pip install ...` trong notebook. Lệnh Git thì không phụ thuộc môi trường Python.
- dbt (từ Tuần 3 Ngày 2): cài trong môi trường `bi` bằng `pip install dbt-bigquery`, chạy trong **Anaconda Prompt** sau `conda activate bi` (không dùng terminal VS Code vì nó dùng Python của `base`). Project dbt là thư mục `bi_dbt/` trong repo (có commit, có `.gitignore` riêng). File kết nối `profiles.yml` nằm **ngoài repo** ở `%USERPROFILE%\.dbt\` và **không commit**. Cấu hình: `method: oauth` (dùng đăng nhập gcloud, không cần file khóa), `project: bq-learning-510104`, `dataset: dbt_dev`, `location: US`, `threads: 4`, `maximum_bytes_billed: 1000000000`. Kiểm tra kết nối: `cd bi_dbt` rồi `dbt debug`, mong đợi `All checks passed!`. Lệnh `python -c "..."` phải nằm trên một dòng.
- Cấu trúc dbt (từ Tuần 3 Ngày 3): `bi_dbt/models/staging/thelook/` chứa `_thelook__sources.yml` (khai báo nguồn) và `stg_thelook__order_items.sql` (model staging, `materialized='view'`). Lệnh dùng: `dbt compile --select <model>` (xem SQL đã biên dịch, không quét byte) và `dbt run --select <model>` (luôn có `--select`, vì `models/example/` còn hai model mẫu). Anaconda Prompt hiển thị tiếng Việt vỡ chữ khi dùng `type`; không phải lỗi file, gõ `chcp 65001` nếu muốn xem đúng.
- Khi gõ lệnh, tên nhánh, tên file: tắt bộ gõ tiếng Việt.
- Pipeline chạy bằng một lệnh: `D:\Installsoftware\Anaconda\envs\bi\python.exe "Python\Day 5\weather_pipeline.py"` (dùng đường dẫn đầy đủ tới Python của `bi`; gõ `python` trong terminal VS Code sẽ dùng `base` và báo thiếu `google.cloud`). Log ghi ra `logs/weather_pipeline.log` (bị `.gitignore` chặn).
- Cấu trúc dbt (từ Tuần 3 Ngày 4): thêm `bi_dbt/models/staging/thelook/stg_thelook__products.sql` (view) và thư mục `bi_dbt/models/marts/` chứa `dim_products.sql`, `fct_net_sales.sql` (cả hai `materialized='table'`, đặt bằng `{{ config(...) }}` trong từng file). Lệnh dùng: `dbt run --select fct_net_sales dim_products stg_thelook__products` (dbt tự xếp thứ tự theo `ref`). Bản dịch SQL nằm ở `bi_dbt\target\compiled\...`, bản chạy thật ở `target\run\...`; `target\` và `logs\` do dbt tự tạo, bị `.gitignore` chặn, không commit. File trong `models/` không bao giờ bị `dbt compile` sửa.
- Power BI (từ Tuần 3 Ngày 5): Power BI Desktop (Windows), connector Google BigQuery, Import mode, Billing Project ID `bq-learning-510104`. Đăng nhập ở tab Organizational account bằng tài khoản Google của GCP (tab Service Account Login cần file khóa JSON nên không dùng). Chỉ nạp `dbt_dev.dim_products` và `dbt_dev.fct_net_sales`, không nạp các view `stg_*`. File `.pbix` lưu ngoài repo (ví dụ `D:\BI\powerbi\`), chưa commit.
- Cấu trúc dbt (từ Tuần 4 Ngày 1): thêm `bi_dbt/models/marts/_marts__models.yml` (khai báo test cho `dim_products` và `fct_net_sales`, có commit). Lệnh dùng: `dbt test --select dim_products fct_net_sales` (`test` là lệnh, `--select` là tùy chọn; dbt chạy mọi test có đụng tới model được chọn, kể cả test `relationships` đặt ở model khác). SQL của từng test nằm ở `bi_dbt\target\compiled\bi_dbt\models\marts\_marts__models.yml\` (tên thư mục là `_marts__models.yml`, do dbt tự tạo, không commit). Notebook tuần 4: `Python/Week 4/Day1.ipynb` (sửa lại nếu bạn đặt tên khác).
- Cấu trúc dbt (từ Tuần 4 Ngày 2): thêm `description` vào `bi_dbt/models/marts/_marts__models.yml` (2 mart và các cột) và vào `bi_dbt/models/staging/thelook/_thelook__sources.yml` (source `thelook` và 4 bảng). Lệnh dùng (Anaconda Prompt, env `bi`, đang ở thư mục `bi_dbt`): `dbt docs generate` (sinh `target\manifest.json` và `target\catalog.json`) và `dbt docs serve` (mở `http://localhost:8080`, dừng bằng `Ctrl+C`). Lệnh dbt phải chạy trong `bi_dbt`, đứng ở thư mục gốc repo thì báo `No dbt_project.yml found`. Notebook: `Python/Week 4/Day2.ipynb`.
- Cấu trúc dbt (từ Tuần 4 Ngày 3): thêm `bi_dbt/models/marts/fct_net_sales_inc.sql` (`materialized='incremental'`, `unique_key='order_item_id'`, `incremental_strategy='merge'`, lọc `status = 'Complete'` và từ lần chạy thứ hai chỉ lấy `order_date >= max(order_date) trong bảng - 3 ngày`) và 4 test mới cho model này trong `_marts__models.yml` (`order_item_id`: `unique`, `not_null`; `product_id`: `not_null`, `relationships`). Lệnh dùng: `dbt run --select fct_net_sales_inc` (lần đầu `CREATE TABLE`, các lần sau `MERGE`; không dùng `--full-refresh` trừ khi muốn dựng lại cả bảng) và `dbt test --select fct_net_sales_inc`. Không comment `--` có dấu ngoặc nhọn trong file SQL vì Jinja vẫn xử lý. Notebook: `Python/Week 4/Day3.ipynb` (sửa lại nếu bạn đặt tên khác).
- Cấu trúc dbt (từ Tuần 4 Ngày 5): thêm `bi_dbt/models/marts/dim_date.sql` (`materialized='table'`, tạo bằng `generate_date_array`, không đọc bảng nguồn, 3.287 dòng từ 2019-01-01 đến 2027-12-31; cột `date_day`, `year_number`, `quarter_number`, `quarter_name`, `month_number`, `month_name`, `year_month`, `weekday_number` (Monday = 1), `weekday_name`) và 3 test mới trong `_marts__models.yml` (`dim_date.date_day`: `unique`, `not_null`; `fct_net_sales.order_date`: `relationships` sang `dim_date.date_day`). Lệnh dùng: `dbt run --select dim_date` và `dbt test --select dim_date fct_net_sales`. Notebook: `Python/Week 4/Day5.ipynb`.
- Power BI (từ Tuần 4 Ngày 5): thêm bảng `dbt_dev.dim_date` (Import), quan hệ `fct_net_sales.order_date` (nhiều) → `dim_date.date_day` (một), Single, cùng với quan hệ `product_id` đã có. Tắt Auto date/time (File → Options and settings → Options → Current File → Data Load). Ẩn cột khóa trong fact (chuột phải cột → Hide; chọn nhiều cột bằng Ctrl) và `month_number`, `weekday_number` trong `dim_date`.
- Power BI (từ Tuần 5 Ngày 1): thêm 4 measure trong bảng `fct_net_sales`: `Net Revenue Men = CALCULATE([Net Revenue], dim_products[department] = "Men")`, `Net Revenue 2025 = CALCULATE([Net Revenue], dim_date[year_number] = 2025)`, `Net Revenue All Products = CALCULATE([Net Revenue], REMOVEFILTERS(dim_products))`, `Revenue % of Total = DIVIDE([Net Revenue], [Net Revenue All Products])`. Đây là measure để học, cố định giá trị Men hoặc năm 2025. Trang báo cáo có slicer `dim_date[year_number]`, 2 Card và 1 Matrix theo `department`. Notebook: `Python/Week 5/Day1.ipynb` (Cell 1 định nghĩa `client`, `mb`, `stats`; Cell 2 đối chiếu theo department và năm 2025; Cell 3 tổng của `fct_net_sales`).

- Power BI (từ Tuần 5 Ngày 2): thêm 3 measure trong bảng `fct_net_sales` (tên trong mô hình là `ytd`, `ly`, `YoY %`): `ytd = IF(ISBLANK([Net Revenue]), BLANK(), TOTALYTD([Net Revenue], dim_date[date_day]))`; `ly` dùng `VAR LastData = CALCULATE(MAX(fct_net_sales[order_date]), REMOVEFILTERS(dim_date))` rồi `CALCULATE([Net Revenue], SAMEPERIODLASTYEAR(dim_date[date_day]), dim_date[date_day] <= EDATE(LastData, -12))`; `YoY % = DIVIDE([Net Revenue] - [ly], [ly])`. Trang báo cáo thêm Matrix theo `year_month` (4 measure) cạnh slicer `year_number`; slicer đã lọc `Net Revenue` is not blank nên không còn năm 2027. Notebook: `Python/Week 5/Day2.ipynb` (Cell 1 định nghĩa `client`, `mb`, `check`, `stats`; Cell 2 SQL tham chiếu 2024 và 2025: doanh thu tháng, YTD, cùng tháng năm trước, YoY; Cell 3 doanh thu cùng kỳ đến ngày dữ liệu cuối).

- Power BI (từ Tuần 5 Ngày 3): thêm 2 measure trong bảng `fct_net_sales`: `Avg Order Value = DIVIDE([Net Revenue], [Orders])`; `Data Through = CALCULATE(MAX(fct_net_sales[order_date]), REMOVEFILTERS(dim_date), REMOVEFILTERS(dim_products))`. Trang `Overview` có: tiêu đề, thẻ `Data Through`, slicer `year_number` (Between) và `department`, 6 thẻ KPI, biểu đồ đường (`Net Revenue` và `ly` theo `year_month`), biểu đồ cột Top 10 category, bảng category. Biểu đồ đường không còn lọc lên các thẻ (Edit interactions). Notebook: `Python/Week 5/Day3.ipynb` (Cell 1 định nghĩa `client`, `mb`, `stats`; Cell 2 Top 10 category 2026; Cell 3 KPI 2026 và mốc dữ liệu cuối).

- Power BI (từ Tuần 5 Ngày 4): file `.pbix` đang dùng tên `W4D4_backup.pbix` (ngoài repo, `D:\BI\`). Trong Power Query (Home, Transform data, Choose columns) đã bỏ `order_item_id`, `user_id`, `cost` khỏi `fct_net_sales` (còn 5 cột) và `product_name` khỏi `dim_products` (còn 4 cột); các cột này vẫn còn trong BigQuery. Notebook: `Python/Week 5/Day4.ipynb` (Cell 1 định nghĩa `client`, `mb`, `check`, `stats`; Cell 2 đo dung lượng `.pbix`; Cell 3 KPI gốc; Cell 4 số giá trị khác nhau từng cột; Cell 5, 5b, 5c tìm job của Power BI trong `INFORMATION_SCHEMA.JOBS`).

- Dữ liệu Olist (ngoài repo, **không commit**, không chép vào `data/`): `D:\BI\projects\ai-logistics\data\olist`, 9 file CSV (`olist_customers_dataset`, `olist_geolocation_dataset`, `olist_order_items_dataset`, `olist_order_payments_dataset`, `olist_order_reviews_dataset`, `olist_orders_dataset`, `olist_products_dataset`, `olist_sellers_dataset`, `product_category_name_translation`). Chưa mở xem tên cột. CSV đang liên kết với Excel: mở bằng VS Code, không lưu lại bằng Excel. Thư mục `D:\BI\Dataset` (5 file nhỏ và `Template.png`) **không phải Olist**, nội dung chưa biết, không dùng cho Project 2. Giấy phép CC BY-NC-SA 4.0 xác nhận ngày 23/10/2026 trên trang Kaggle của Olist.
- Thư mục `Doc/` (từ Tuần 5 Ngày 6): `Dashboard.png`, `PowerBI_Model.png`, `dbt_lineage.png`, `star_schema.png`, `Definition_of_done.md` (6 mục Project 1, đã tích đủ). Tên file phải khớp từng chữ với README (GitHub phân biệt hoa thường).
- Repo Project 2 (từ Tuần 6 Ngày 1): `olist-bi-project` (Public, tài khoản `khoatranuk-sys`), thư mục trên máy `D:\BI\projects\olist-bi-project`. `.gitignore` (mẫu Python của GitHub + khối luật riêng ở cuối: `.env`, `data/`, `olist/`, `*.csv`, `*.parquet`, `*.pbix`, `logs/`, `target/`, `dbt_packages/`). `.env` (không commit) và `.env.example` (có commit) có 3 biến: `OLIST_DIR`, `GCP_PROJECT`, `BQ_LOCATION`. Notebook: `Notebook/Week01/Day1.ipynb` (thư mục tên viết hoa, số ít). Dùng lại project GCP `bq-learning-510104`, không tạo project mới; Project 2 tách bằng dataset riêng.
- Project 2 (từ Tuần 6 Ngày 3): dataset `bq-learning-510104.olist_raw` (US), mọi cột nạp dạng STRING, ép kiểu ở dbt staging. Notebook `Notebook/Week03/Day3.ipynb` (sửa lại nếu bạn đặt tên khác). Hàm dùng lại: `load_csv_as_string(csv_path, table_name)` (đọc tiêu đề bằng `pd.read_csv(nrows=0)`, khai báo schema toàn STRING, `LoadJobConfig` với `skip_leading_rows=1`, `WRITE_TRUNCATE`, `allow_quoted_newlines=True`, `load_table_from_file` trong khối `with open(..., "rb")`).
- Project 2 (từ Tuần 6 Ngày 4): dataset `olist_raw` có 9 bảng, tất cả cột STRING: `customers`, `geolocation`, `order_items`, `order_payments`, `order_reviews`, `orders`, `products`, `sellers` (bỏ `olist_` và `_dataset` khỏi tên file) và `product_category_translation` (Ngày 3). Notebook `Notebook/Week04/Day4.ipynb` (sửa lại nếu bạn đặt tên khác). Cell 1 định nghĩa `client`, `mb`, `check`, `stats`; Cell 2 hàm `load_csv_as_string` (tiêu đề đọc bằng `encoding="utf-8-sig"`); Cell 3 vòng lặp nạp 8 bảng và so 4 số dòng (file CSV, `job.output_rows`, `num_rows`, số Ngày 2); Cell 4 kiểm cột và kiểu; Cell 5 và 5b kiểm `order_reviews` và mã zip.

- Project 2 (từ Tuần 6 Ngày 5): dbt nằm trong `olist_dbt/` (repo `olist-bi-project`, có commit), profile `olist_dbt` trong `%USERPROFILE%\.dbt\profiles.yml` (`method: oauth`, `project: bq-learning-510104`, `dataset: olist_dbt_dev`, `location: US`, `threads: 4`, `maximum_bytes_billed: 1000000000`; khối `bi_dbt` của Project 1 giữ nguyên). `dbt_project.yml`: `staging` là `view`, `marts` là `table`. Cấu trúc: `olist_dbt/models/staging/olist/` chứa `_olist__sources.yml` (source `olist` trỏ `olist_raw`, 9 bảng), `stg_olist__orders.sql` (view, `SAFE_CAST` 5 cột ngày) và `_olist__models.yml` (mô tả và 2 test `unique`, `not_null` trên `order_id`). Lệnh dùng (Anaconda Prompt, env `bi`, đang ở `olist_dbt`): `dbt compile --select stg_olist__orders`, `dbt run --select stg_olist__orders`, `dbt test --select stg_olist__orders`. Notebook: `Notebook/Week01/Day05.ipynb` (tên thật mình đặt; Cell 1 định nghĩa `client`, `mb`, `check`, `stats`; Cell 2 so NULL trước và sau `SAFE_CAST`; Cell 3 kiểm view; Cell 4 đếm `order_status`). Luật `.gitignore` `olist/` đã đổi thành `/olist/` vì chặn nhầm `olist_dbt/models/staging/olist/`.

## 5. Chi phí và an toàn

- Budget alert chỉ gửi thông báo, không chặn chi tiêu; quota `Query usage per day` của project mới là cầu chì cứng (vượt thì query lỗi `usageQuotaExceeded`). 
- Billing đã bật (Free Trial). Budget bq-learning-budget: 100.000 VND/tháng, ngưỡng 10/50/90/100% (Actual), áp dụng All projects, đã bỏ tick Savings để không trừ tín dụng. Không bật spend cap. Budget chỉ gửi thông báo, không chặn chi tiêu.
- Quota: không sửa được trên Free Trial (nút Edit quota bị mờ). Việc phải làm ngay sau khi nâng cấp trả phí: đặt Query usage per day và Query usage per day per user = 51200 MiB (50 GiB). Xem đơn vị hiển thị trước khi lưu.
- Cầu chì hiện có: `maximum_bytes_billed` trong code Python và trong `profiles.yml` của dbt (1000000000 byte, khoảng 1 GB cho mỗi query dbt gửi đi; vượt thì query bị từ chối, không tính tiền). Quota cấp project chưa có cho tới khi nâng cấp.
- Quyết định nâng cấp trả phí phải xong trước 06/01/2027 (có lời nhắc điện thoại ngày 15/12/2026).
- Repo công khai: không đưa Billing account ID, email, số thẻ vào repo hoặc ghi chú.
- Data Studio gửi khoảng 4 query mỗi lần đổi bộ lọc (mỗi thẻ và biểu đồ một query), mỗi query billed tối thiểu 10 MB; query giống hệt lần trước có thể lấy từ cache (processed 0). Chưa chia sẻ dashboard ra ngoài: phần chia sẻ gắn với IAM, làm sau.
- Luôn xem bytes ước lượng trước khi chạy, dùng dry run và `maximum_bytes_billed` trong Python.
- Không dùng `SELECT *` trên bảng lớn. Bytes billed có mức tối thiểu 10 MB mỗi bảng được tham chiếu.
- Power BI dùng Import mode, tránh DirectQuery.
- Gọi API: luôn đặt `timeout`; với API miễn phí nghỉ giữa các lần gọi (`time.sleep`) để không bị 429.
- API key (nếu có, API thật của khách): không viết thẳng vào code vì repo công khai; đã học ở Ngày 4: để khóa trong `.env` (đã bị `.gitignore` chặn), đọc bằng `python-dotenv`, chỉ commit `.env.example`.
- Power BI không dùng `maximum_bytes_billed`; cầu chì hiện là kích thước bảng nhỏ. Import mode chỉ tốn byte lúc Load/Refresh (mỗi bảng có thể bị tính tối thiểu 10 MB); lọc và bấm biểu đồ sau khi đã Load không tốn byte. Không Publish, không đặt scheduled refresh khi chưa hiểu phần chia sẻ.
- dbt test (từ Tuần 4 Ngày 1): mỗi test là một query gửi lên BigQuery, billed tối thiểu 10 MB mỗi bảng được đọc (`relationships` đọc 2 bảng); mỗi query bị chặn bởi `maximum_bytes_billed: 1000000000` trong `profiles.yml`. Chạy test không tạo bảng. Chi phí cả buổi chưa đo (ước tính vài trăm MB, dưới 0,01 USD).
- Chi phí thật của dbt (đo ngày 14/10/2026 bằng `INFORMATION_SCHEMA.JOBS`, nhận ra query dbt nhờ chú thích `/* {"app": "dbt"` ở đầu query): `dbt test` ngày 13/10 gồm 15 query, tổng 90 MB billed (query chạy lại giống hệt thì lấy từ cache, billed 0). `dbt docs generate` gửi 2 query catalog (mỗi dataset một query, mỗi query đọc 5 bảng hệ thống, processed 40 MB, billed 50 MB), tổng 100 MB mỗi lần và không dùng cache; chạy 2 lần trong ngày 14/10. `dbt docs serve` không gọi BigQuery. `dbt compile` không gửi query. Chỉ chạy `docs generate` khi mô tả hoặc cấu trúc đã đổi.
- dbt test (Tuần 4 Ngày 5): `dbt run --select dim_date` báo `CREATE TABLE (3.3k rows, 0 processed)`, không quét byte. `dbt test --select dim_date fct_net_sales` chạy 7 test (chi phí chưa đo bằng `INFORMATION_SCHEMA.JOBS`, ước tính dưới 100 MB). Query đọc hai bảng (Cell 3, Cell 4) billed 20 MB, một bảng nhỏ (Cell 2) billed 10 MB (processed 0,03 MB): ủng hộ giả thuyết "mức tối thiểu 10 MB tính theo từng bảng" (mới vài lần đo, chưa có tài liệu xác nhận).
- Tuần 5 Ngày 1: `dbt run --select dim_products fct_net_sales` (`PASS=2`, `CREATE TABLE` 45,3 nghìn dòng 10,5 MiB và 29,1 nghìn dòng 2,5 MiB) rồi `dbt test --select dim_products fct_net_sales dim_date` (`PASS=11 TOTAL=11`, gồm cả test `relationships` của `fct_net_sales_inc` vì nó đụng tới `dim_products`). Cell 2 billed 20 MB (hai bảng), Cell 3 billed 10 MB (một bảng). Chi phí của 11 test và của Refresh Power BI chưa đo.
- Tuần 5 Ngày 2: chỉ có Cell 2 và Cell 3 đọc `fct_net_sales` (một bảng): Cell 3 processed 0,69 MB, billed 10 MB. Power BI Import mode không tốn byte khi tạo measure, lọc, bấm slicer. Không `dbt run`, không `dbt test`, không Refresh Power BI trong ngày.
- Tuần 5 Ngày 4: Cell 3 và Cell 4 mỗi cell đọc một bảng, billed 10 MB. Mỗi cell đọc `INFORMATION_SCHEMA.JOBS` (Cell 5, 5b) billed 20 MB, processed 0,01 MB (lần thứ nhiều mà chưa hiểu); Cell 5c in `None` và `0.0 MB`. Lần Close & Apply (bỏ cột) không thấy trong `JOBS` trong 24 giờ và 60 phút; Billing Reports ngày 22/10 chưa có dòng chi phí nào (báo cáo nói chi phí có thể chậm hơn 24 giờ). Byte Refresh của Power BI vẫn chưa biết; không ghi "miễn phí".
- Tuần 5 Ngày 6: Billing Overview ngày 24/10/2026 hiện tổng chi phí ₫0, tín dụng dùng thử còn nguyên, còn 73 ngày (hết 06/01/2027). Chi phí có thể trễ hơn 24 giờ; chưa chứng minh Refresh Power BI miễn phí. `dbt test` 4 mart (14 test) chạy 24,72 giây, chi phí thật chưa đo.
- **Tuần 6, Ngày 1**: tạo repo `olist-bi-project`.
  - **Repo**: tạo trên GitHub (Public, README, `.gitignore` Python, không chọn License), clone về `D:\BI\projects\olist-bi-project`. Thêm khối luật vào `.gitignore` trước khi có file dữ liệu. `git check-ignore -v` xác nhận bị chặn: `.env` (dòng 224), `data/` (dòng 225), `*.pbix` (dòng 229).
  - **README khởi đầu** (tiếng Anh): mục tiêu, nguồn dữ liệu (Brazilian E-Commerce Public Dataset by Olist), giấy phép CC BY-NC-SA 4.0, ghi rõ dữ liệu không nằm trong repo và dự án chỉ để học và portfolio, không dùng cho khách trả tiền (tiêu chí 8).
  - **Notebook** `Notebook/Week01/Day1.ipynb`: đọc `OLIST_DIR` từ `.env` bằng `python-dotenv`, liệt kê file `.csv`, đọc tiêu đề bằng `pd.read_csv(f, nrows=0)`. [ĐIỀN: số file và tên cột thật từ output Cell 2]
  - **Commit**: 3 commit trên GitHub (1 của GitHub, 2 của mình): `Add project skeleton: README, .gitignore rules, .env.example` và `Add Day 1 notebook: list Olist files and columns`. Không có `.env` trên GitHub.
  - **Chi phí**: không đụng BigQuery nên không tốn byte.
  - **Checklist Excel**: tick việc tạo repo Project 2 của Tuần 6 (kiểm tra lại tên dòng và số tổng hiển thị).
  - Tuần 6 Ngày 3: tạo dataset và load job không tốn byte truy vấn. Chỉ Cell 4 (SQL đếm dòng một bảng) billed 10 MB (processed làm tròn 0,0 MB).
  - Tuần 6 Ngày 4: 8 load job không tốn byte truy vấn. Cell 5 (một bảng) processed 2,81 MB, billed 10 MB; Cell 5b (ba bảng) processed 7,36 MB, billed 30 MB: thêm một lần đo ủng hộ giả thuyết "mức tối thiểu 10 MB tính theo từng bảng" (chưa có tài liệu xác nhận). Tổng khoảng 40 MB billed.

  - Tuần 6 Ngày 5: `dbt run` view không quét byte; Cell 2, 3, 4 mỗi cell đọc một bảng, processed 9,86 / 5,22 / 1,04 MB, billed 10 MB mỗi cell (tổng khoảng 30 MB); `dbt test` 2 test chạy 8,25 giây, chi phí chưa đo.

## 6. Lộ trình 8 tuần (tóm tắt)
| Tuần | Nội dung chính |
|---|---|
| 1 | Mô hình dữ liệu (star schema, SCD), Python cho pipeline (API, retry, Parquet), Git, thiết lập BigQuery |
| 2 | BigQuery sâu (load job, partitioning, clustering, INFORMATION_SCHEMA, IAM), Looker Studio |
| 3 | Bật billing + kiểm soát chi phí, dbt phần 1 (source, staging, mart), Power BI kết nối BigQuery |
| 4 | dbt phần 2 (test, docs, incremental), DAX cơ bản, star schema trong Power BI, cập nhật CV và LinkedIn |
| 5 | Power BI nâng cao (DAX, thiết kế dashboard), hoàn thành Project 1 (dữ liệu mô phỏng, học công cụ), chốt ngách và dữ liệu thật |
| 6 | Tự động hóa (Python API/Sheets vào BigQuery, scheduled query), nạp dữ liệu thật cho Project 2 |
| 7 | Project 2 (dữ liệu thật), case study |
| 8 | Portfolio, CV, luyện phỏng vấn |
| 9-10 | Project thành thạo: bộ dữ liệu logistics/e-commerce khác Olist, làm từ đầu, ít xem hướng dẫn |
| Tùy chọn / Hoãn | dbt snapshot (SCD Type 2), gói dịch vụ freelance; hướng DE (Docker, Airflow, Terraform, Spark) |

Tuần 1 chi tiết: Ngày 1 thiết lập, Ngày 2 mô hình dữ liệu, Ngày 3 Python cho pipeline (1), Ngày 4 Python (2) + Git, Ngày 5 mini project (API → làm sạch → BigQuery, có logging, README), Ngày 6 ôn tập.
- Từ 17/10/2026: hai việc CV và LinkedIn của Tuần 4 (cập nhật CV/LinkedIn; viết mục kinh nghiệm 6 năm BI logistics có số liệu) chuyển về Tuần 8. Tuần 4 còn 5 việc, đều xong.

## 7. Đã hoàn thành
- **Ngày 1 (Tuần 1)**: tạo project GCP, chạy query đầu tiên trên `bigquery-public-data.thelook_ecommerce`, cài gcloud, tạo môi trường `bi`, cài Git, tạo repo GitHub, chạy query BigQuery từ Python (có dry run và giới hạn bytes), viết `notes.md`.
- **Ngày 2**: mô hình dữ liệu, xây star schema từ `thelook_ecommerce`.
  - **Khái niệm đã nắm** (viết bằng lời mình trong `Notes.md`): fact, dimension, grain, star schema, surrogate key, SCD Type 1/2/3. Các dimension chỉ nối vào fact, không nối với nhau.
  - **Khám phá nguồn**: `order_items` là fact (grain: 1 mặt hàng trong 1 đơn), `orders` không hợp grain vì không có `product_id`, `users` và `products` là dimension. Đã kiểm tra bằng dữ liệu thật: `order_items.id` duy nhất, `product_id` và `user_id` nối được sang `products.id` và `users.id` (0 dòng không khớp).
  - **Dataset** `bq-learning-510104.dwh` (location US, bảng tự hết hạn sau 60 ngày do sandbox). Số dòng chạy ngày 30/09/2026 (dữ liệu nguồn công khai nên có thể đổi theo thời gian):

    | Bảng | Số dòng | Khóa chính | Ghi chú |
    |---|---|---|---|
    | `dim_date` | 3.287 | `date_key` (YYYYMMDD) | Phủ 2019-01-01 đến 2027-12-31, có year, quarter, month, day_name |
    | `dim_users` | 100.000 | `user_id` | Là SCD Type 1 (mỗi khách một dòng) |
    | `dim_products` | 29.120 | `product_id` | name, category, brand, department |
    | `fact_order_items` | 180.771 | `order_item_id` | Có `order_id`, `user_id`, `product_id`, `order_date_key`, `status`, `sale_price`, `cost`, `gross_profit` |

  - **Kiểm tra fact**: đúng grain (không dòng trùng), số dòng bằng bảng nguồn, `cost` và `gross_profit` không NULL, `order_date_key` nối được `dim_date` (0 dòng không khớp, join không nhân dòng).
  - **Báo cáo**: doanh thu và lợi nhuận theo danh mục và quý (năm 2025, 104 dòng). Bản đầu tính cả đơn Cancelled và Returned, khi tính thực tế sẽ loại hai trạng thái này.
  - **Bài tập SCD**: khách A đổi từ Hà Nội sang TP.HCM ngày 01/06/2025. Đơn ngày 15/03/2025 tính vào TP.HCM ở Type 1 và Type 3, vào Hà Nội ở Type 2. Kết luận: Type 2 gắn đơn hàng với thông tin đúng tại thời điểm đặt hàng.
  - **Sản phẩm bàn giao**: sơ đồ star schema (`Doc/star_schema.png`), SQL trong `SQL/Day 2/`, ghi chú Ngày 2 trong `Notes.md`, notebook `Day2.ipynb`.
- **Ngày 3**: Python cho pipeline (1), tức bước Extract (lấy dữ liệu từ API). Notebook `Python/Day 3/Day3.ipynb`.
  - **Gọi API** Open-Meteo (`https://api.open-meteo.com/v1/forecast`) bằng `requests`: `params`, `headers`, `timeout`; đọc `r.status_code`, `r.url`, `r.json()`. Dữ liệu `daily` xếp theo cột (mỗi chỉ số một danh sách 7 phần tử, cùng vị trí là cùng một ngày). Đã thử đổi `forecast_days` và tọa độ để thấy chỉ cần đổi `params` là lấy được dữ liệu khác.
  - **Mã lỗi** (đã thử với `latitude=999` → 400, API trả `reason` giải thích): 2xx thành công; 4xx là lỗi ở yêu cầu của mình, phải sửa rồi mới chạy lại (không retry); 429 là mình gọi quá nhiều, chờ và gọi thưa hơn; 5xx là lỗi phía server, có thể retry; mất mạng hoặc quá thời gian thì không có mã (`Timeout`, `ConnectionError`), cũng retry được. Mã 200 chỉ nói yêu cầu thành công, chưa nói dữ liệu đã đủ.
  - **Phân trang** (jsonplaceholder, `_page`, `_limit`): hàm `fetch_all` lặp từng trang đến khi nhận trang rỗng, có `max_pages` làm phanh an toàn. Lấy đủ 100 bài, luôn đối chiếu tổng số sau khi lấy (thiếu dữ liệu mà không có lỗi là kiểu sai nguy hiểm nhất).
  - **Retry và backoff**: hàm `get_json(url, params, headers, retries=4, timeout=10)` retry khi 5xx, 429, `Timeout`, `ConnectionError` (chờ 2, 4, 8 giây), dừng ngay với 4xx khác, hết số lần thì ném `RuntimeError` rõ ràng. Đã thử: gọi đúng thì trả dữ liệu, `latitude=999` dừng ngay, `httpbin.org/status/503` retry rồi báo lỗi. Hàm này là mẫu dùng lại cho các ngày sau.
  - **Biến thành bảng**: lặp 3 thành phố (Hà Nội, TP HCM, Đà Nẵng), mỗi thành phố một DataFrame, thêm cột `city`, `pd.concat` thành bảng 21 dòng × 6 cột (`time`, `temperature_2m_max`, `temperature_2m_min`, `precipitation_sum`, `city`, `ingested_at`), đổi `time` sang kiểu ngày. Đã kiểm tra: mỗi thành phố 7 dòng, không có giá trị thiếu.
  - **Lưu file** vào `data/`: `weather.csv` 1.350 bytes, `weather.json` 4.276 bytes, `weather.parquet` 4.616 bytes. Bảng nhỏ thì Parquet không nhỏ nhất (có phần tiêu đề cố định); lợi thế dung lượng chỉ rõ với bảng lớn. Lý do ưu tiên Parquet khi nạp BigQuery là **giữ đúng kiểu dữ liệu**: đọc lại CSV thì `time` thành chữ (`str`), đọc lại Parquet vẫn là `datetime64`. Parquet là định dạng nhị phân nên không mở được bằng trình soạn thảo chữ, đọc bằng `pd.read_parquet`.
  - **An toàn**: thêm `data/` vào `.gitignore` (đã kiểm tra `data/` không xuất hiện trong danh sách thay đổi của Git).
  - **Chưa làm trong Ngày 3** (có thể bổ sung nhanh): đọc lại `weather.json` bằng `pd.read_json` (checklist có chữ "đọc/ghi JSON").
- **Ngày 4**: Python cho pipeline (2) + Git. Notebook `Python/Day 4/Day4.ipynb`.
  - **Bù Ngày 3**: đã đọc lại `weather.json` bằng `pd.read_json`.
  - **Query an toàn**: `check(sql)` (dry run) và `run(sql, max_mb)` (`maximum_bytes_billed`). Thử `max_mb=1` thì bị chặn với `bytesBilledLimitExceeded` (cần tối thiểu 10 MB dù ước lượng chỉ 1,77 MB); lỗi hiển thị là `InternalServerError 500` nhưng không phải lỗi server, nguyên nhân nằm ở giới hạn mình đặt. Chạy `max_mb=100` thì ra đủ 5 trạng thái, tổng 180.771 dòng, khớp `fact_order_items`.
  - **Nạp DataFrame lên BigQuery**: dataset `bq-learning-510104.raw` (US), bảng `raw.weather_daily` 21 dòng. Schema khai báo rõ: `time` DATE, `temperature_2m_max` FLOAT, `temperature_2m_min` FLOAT, `precipitation_sum` FLOAT, `city` STRING, `ingested_at` TIMESTAMP. Trước khi nạp: `df["time"].dt.date` và `ingested_at = pd.Timestamp.now(tz="UTC")`. Kiểm tra bằng `get_table` và SQL (3 thành phố × 7 ngày, 2026-10-01 đến 2026-10-07).
  - **Thí nghiệm chạy lại**: `WRITE_APPEND` làm bảng thành 42 dòng (trùng, không báo lỗi); `WRITE_TRUNCATE` đưa về 21 dòng. Ba chế độ: `WRITE_TRUNCATE` (xóa cũ ghi mới), `WRITE_APPEND` (nối thêm), `WRITE_EMPTY` (chỉ ghi nếu bảng trống). Pipeline chạy lại nhiều lần cho cùng kết quả gọi là idempotent.
  - **Git**: làm đủ một vòng: nhánh (`git switch -c`), `git add` từng file, `git commit -m`, `git push -u origin`, Pull Request trên GitHub, merge, `git pull` về máy, `git branch -d` xóa nhánh. Đã làm hai PR (#1 notebook, #2 `.env.example`).
  - **Bảo vệ bí mật**: `.gitignore` (mẫu Python của GitHub) đã chặn `.env` ở dòng 151 (kiểm tra bằng `git check-ignore -v .env`). Khóa để trong `.env`, đọc bằng `python-dotenv` (`load_dotenv`, `os.getenv`); `.env.example` chứa tên biến, không chứa khóa thật. Không `print` khóa vì output notebook cũng bị commit. Đã kiểm tra trên GitHub: có `.env.example`, không có `.env`. Các file `Ghi_chu.txt`, `test_bq.ipynb`, `viewtable.ipynb` chỉ là nội dung thử; `.vscode/settings.json` chỉ có 2 dòng cấu hình conda, an toàn.
  - **Checklist Excel**: xong 3 việc Ngày 4.
- **Ngày 5**: mini project. Notebook `Python/Day 5/Day5.ipynb` (thử từng mảnh) và script `Python/Day 5/weather_pipeline.py` (chạy một lệnh).
  - **Logging**: `logging.basicConfig(level, format, force=True)`, các mức DEBUG/INFO/WARNING/ERROR; script ghi cả ra màn hình và file `logs/weather_pipeline.log` (`FileHandler`, ghi nối thêm).
  - **Extract**: `get_json` (timeout, retry backoff `2 ** attempt` với 5xx/429/mất mạng, dừng ngay với 4xx khác 429) và `extract_weather` lặp qua dictionary `CITIES` (3 thành phố, 7 ngày), nghỉ 1 giây giữa các lần gọi.
  - **Transform**: `transform_weather` gom thành DataFrame 21 dòng, 6 cột (`pd.concat` giống UNION ALL, thêm cột `city`, `time` về DATE, `ingested_at` UTC). `ingested_at` là thời điểm lấy dữ liệu, không phải lúc nạp.
  - **Kiểm tra chất lượng trước khi nạp**: `validate_weather` kiểm tra số dòng (3 × 7), giá trị thiếu, trùng `(city, time)` (kiểm tra grain), max nhỏ hơn min, mưa âm. Thử làm hỏng dữ liệu thì báo cả 3 lỗi một lượt và dừng, không nạp.
  - **Load**: `load_weather` dùng schema khai báo rõ + `WRITE_TRUNCATE`, đối chiếu `job.output_rows` với số dòng gửi lên. Bảng `raw.weather_daily` giờ chứa 2026-10-02 đến 2026-10-08.
  - **Điều phối**: `main()` chạy 4 bước theo thứ tự, `try/except` + `log.exception` ghi dấu vết lỗi, trả mã thoát 0 (thành công) hoặc 1 (thất bại) qua `sys.exit(main())`.
  - **Lần chạy thật đầu tiên**: gặp `ReadTimeout` ở Da Nang, retry thành công ở lần 2; log ghi lại đủ. Tổng 26,2 giây.
  - **README**: viết lại `README.md` (mục tiêu, sơ đồ luồng Mermaid, bảng cột `raw.weather_daily`, ảnh star schema, cách chạy, cấu trúc thư mục, lưu ý an toàn).
  - **Checklist Excel**: xong 2 việc Ngày 5.
- **Ngày 6**: ôn tập, trả lời từng câu rồi ghi vào `Notes.md` (cùng với ghi chú Ngày 5).
  - **Grain**: một dòng của bảng fact đại diện cho cái gì. `fact_order_items` có grain là một order item (một món hàng trong một đơn), nên một sản phẩm xuất hiện ở nhiều dòng. Phải chốt grain trước vì nó quyết định cột nào đưa vào bảng, nối được dimension nào, và tránh cộng trùng. Kiểm tra trùng `(city, time)` ở bảng thời tiết chính là kiểm tra grain.
  - **SCD 1 và SCD 2** (khách đổi từ Hà Nội sang TP HCM): SCD 1 ghi đè nên mất lịch sử và làm đổi báo cáo quá khứ; SCD 2 thêm dòng mới (surrogate key, `valid_from`, `valid_to`, `is_current`) nên giữ nguyên báo cáo quá khứ, nhưng bảng to hơn và phép nối phức tạp hơn.
  - **Tránh `SELECT *`**: BigQuery lưu theo cột và tính tiền theo số byte của các cột mà query đọc; `SELECT *` đọc tất cả cột nên đắt, `LIMIT` không giảm chi phí. Chỉ chọn cột cần, dry run để ước lượng, `maximum_bytes_billed` làm cầu chì; sau này lọc theo cột partition.
  - **Checklist Excel**: **Tuần 1 hoàn tất 16/16**; tính chung Tuần 1-8 là 16/61.

- **Tuần 2, Ngày 3**: clustering và `INFORMATION_SCHEMA.JOBS`.
  - **Clustering**: `CREATE ... CLUSTER BY product_id`. Bảng `lab.fact_items_clu` (bản sao có clustering của `fact_items_plain`, khoảng 14 MB, 180.771 dòng). Trên bảng nhỏ không thấy khác biệt vì cả hai bị tính tối thiểu 10 MB.
  - **Thí nghiệm bảng lớn** (`big_plain` và `big_clu`, mỗi bảng khoảng 2,5 GB, tạo bằng cách nhân dòng, đã xóa sau khi đo): lọc `product_id` đọc 499,26 MB (billed 500 MB) trên bảng thường và 6,97 MB (billed 10 MB) trên bảng clustered, ít hơn khoảng 72 lần. Dry run bảng clustered là cận trên (lần đo này trùng với số thật).
  - BigQuery chỉ đọc các cột được nhắc đến: 499 MB là hai cột `product_id` và `sale_price`, không phải cả bảng.
  - **`INFORMATION_SCHEMA.JOBS`** (`region-us`): view hệ thống, thời gian theo UTC (giờ Việt Nam = UTC + 7); đọc `total_bytes_processed`, `total_bytes_billed`, `referenced_tables`; không chọn `user_email` vì repo công khai.
  - Dataset `lab` còn 4 bảng: `fact_items_plain`, `fact_items_part`, `fact_items_clu`, `fact_items_recent`.
  - **Ôn Python cuối ngày**: xong 6/6 dòng (`client`, vòng `for`, `dry_run`, `job.result()`, `to_dataframe`, `delete_table`).
  - **Checklist Excel**: xong 2 việc; Tuần 2 là 4/7, tổng 20/61.

- **Tuần 2, Ngày 4**: IAM, view, materialized view.
  - **IAM**: mình là Owner của project. Dataset `lab` có 4 mục quyền (OWNER, WRITER, READER của các nhóm đặc biệt, thêm OWNER của chính mình), đọc bằng `ds.access_entries` (không in `entity_id` vì có thể là email). Người khác muốn chạy query cần cả Data Viewer (trên dataset) và Job User (trên project), thiếu một thì bị 403. Nguyên tắc quyền tối thiểu. Chưa cấp quyền cho ai.
  - **Quy tắc doanh thu**: chỉ tính đơn `Complete` (45.282 dòng). Giá trị trạng thái thật (đếm bằng `GROUP BY status`): Shipped 53.996, Complete 45.282, Processing 36.063, Cancelled 27.373, Returned 18.057 (tổng 180.771). Tên đúng là `Shipped`, không phải `Shipping`.
  - **View** `lab.v_net_sales` (`order_item_id`, `order_date`, `product_id`, `status`, `sale_price`, `gross_profit`, lọc `status = 'Complete'`): view chỉ lưu câu SQL nên không giảm byte (hỏi qua view và hỏi thẳng bảng gốc đều quét 3,15 MB, billed 10 MB, cùng kết quả 45.282 dòng, doanh thu khoảng 2,70 triệu).
  - **Materialized view** `lab.mv_net_sales_daily` (`order_date`, `so_dong`, `net_revenue`, `gross_profit`, gom theo ngày, chỉ `Complete`): sandbox cho tạo. Cùng phép tính quét 0,06 MB so với 3,15 MB (ít hơn khoảng 52 lần), billed vẫn 10 MB. Đánh đổi: tốn chỗ lưu và chi phí làm mới, đổi lấy truy vấn rẻ. Chưa kiểm chứng: MV tự cập nhật khi bảng gốc đổi, và phí làm mới sau khi bật billing.
  - **Kiểm tra độc lập**: `dwh.fact_order_items` với `status = 'Complete'` cho 45.282 dòng, doanh thu 2.702.568, lợi nhuận 1.402.617, biên 51,9% (quét 4,53 MB).
  - **Ôn Python cuối ngày**: xong 6/6 dòng (`get_table`, hàm `mb` trả `None`, `for entry in ds.access_entries`, `client.query(ddl).result()`, `.to_dataframe()`, f-string với `"""`).

- **Tuần 2, Ngày 5**: dashboard đầu tiên bằng Data Studio.
  - **Data Studio** là tên mới của Looker Studio (đổi lại tháng 4/2026), khác Looker (trả phí, dành cho doanh nghiệp). Miễn phí; tiền (nếu có) chỉ đến từ query gửi xuống BigQuery. Kết nối: BigQuery, project `bq-learning-510104`, dataset `lab`, bảng `mv_net_sales_daily`.
  - **Dashboard**: 4 thẻ (Net Revenue, so_dong, Gross Profit, Margin = tổng `gross_profit` chia tổng `net_revenue`, định dạng %), biểu đồ đường theo Year Month, Date range control. Tổng toàn bộ: 2.702.568 / 45.282 / 1.402.617 / 51,9%. Khoảng 15/01/2025 đến 06/10/2026: 1.529.873 / 25.658 / 793.321 / 51,9% (khớp SQL). Chưa chia sẻ.
  - **Lỗi nhìn nhầm trên dashboard**: `Month` là tháng trong năm (cộng dồn các năm), phải dùng Year Month; bấm vào một điểm trên biểu đồ làm các thẻ lọc theo điểm đó (cross-filtering, bấm lại hoặc Reset); các thẻ có theo bộ lọc ngày nhưng cập nhật chậm hơn biểu đồ nên lúc đó thấy số cũ (đối chiếu bằng SQL cho chắc); `Record Count` là số ngày, không phải số đơn; Margin phải là tổng chia tổng.
  - **Số liệu**: tháng 10/2026 mới có 3 ngày (291 dòng, 17.678) nên đường biểu đồ rơi; tháng 9/2026 là đỉnh (3.447 dòng, 201.674), doanh thu mỗi dòng gần như không đổi (khoảng 58,5 đến 60,9) nên đỉnh đến từ số dòng; dữ liệu là mô phỏng.
  - **`INFORMATION_SCHEMA.JOBS`**: mỗi thẻ và biểu đồ là một query riêng, bộ lọc ngày thành `WHERE order_date >= ... AND ... <= ...`, mỗi query chạy 0,2 đến 0,5 giây trong BigQuery, processed 0,04 đến 0,06 MB, billed 10 MB; query giống hệt (`cache_hit = TRUE`) thì processed và billed bằng 0. Cảm giác chậm không đến từ BigQuery. Trong khoảng 8 phút chỉnh bộ lọc có ít nhất 15 query billed (khoảng 150 MB).
  - **Ôn Python cuối ngày**: xong 6/6 dòng (`.to_dataframe()`, `for _, row in df_q.iterrows()`, `print("-" * 60)`, `QueryJobConfig(use_query_cache=False, maximum_bytes_billed=...)`, f-string với `"""`, `print(row["query"])`). Cell 14 ban đầu không in gì vì `INTERVAL 1 HOUR` làm `df_q` rỗng; nới 24 giờ thì ra.
  - **Checklist Excel**: xong 3 việc (IAM, view, MV; kết nối; dashboard); **Tuần 2 hoàn tất 7/7**, tổng 23/61.
  - **Repo**: tạo trên GitHub (Public, README, `.gitignore` Python, không chọn License), clone về `D:\BI\projects\olist-bi-project`. Thêm khối luật vào `.gitignore` trước khi có file dữ liệu. `git check-ignore -v` xác nhận bị chặn: `.env` (dòng 224), `data/` (dòng 225), `*.pbix` (dòng 229).
  - **README khởi đầu** (tiếng Anh): mục tiêu, nguồn dữ liệu (Brazilian E-Commerce Public Dataset by Olist), giấy phép CC BY-NC-SA 4.0, ghi rõ dữ liệu không nằm trong repo và dự án chỉ để học và portfolio, không dùng cho khách trả tiền (tiêu chí 8).
  - **Notebook** `Notebook/Week01/Day1.ipynb`: đọc `OLIST_DIR` từ `.env` bằng `python-dotenv`, liệt kê file `.csv`, đọc tiêu đề bằng `pd.read_csv(f, nrows=0)`. [ĐIỀN: số file và tên cột thật từ output Cell 2]
  - **Commit**: 3 commit trên GitHub (1 của GitHub, 2 của mình): `Add project skeleton: README, .gitignore rules, .env.example` và `Add Day 1 notebook: list Olist files and columns`. Không có `.env` trên GitHub.
  - **Chi phí**: không đụng BigQuery nên không tốn byte.
  - **Checklist Excel**: tick việc tạo repo Project 2 của Tuần 6 (kiểm tra lại tên dòng và số tổng hiển thị).

- Tuần 3, Ngày 1: billing, kiểm soát chi phí, gỡ hạn tự xóa của sandbox.
 - Billing, budget, quota: xem mục 5.
 - Gỡ hạn ở 3 tầng (Cell 4): dataset (default_table_expiration_ms, default_partition_expiration_ms = None), từng bảng/view/MV (t.expires), partition (time_partitioning.expiration_ms). Áp dụng cho lab, dwh, raw, tổng 16 đối tượng (lab 6, dwh 4, raw 6), không có dòng LỖI. View và MV cũng bị gắn hạn nên cũng phải gỡ. Bảng fact_items_part cũ chỉ bị gỡ phần partition, đúng với giả thuyết hạn partition làm mất các tháng cũ.
 - Tạo lại lab.fact_items_part (Cell 5, partition theo tháng trên order_date, require_partition_filter = TRUE): 180.771 dòng, từ 2019-01-11 đến 2026-10-04, khớp fact_items_plain. Kiểm tra bằng query quét 1,38 MB, billed 10 MB.
 - Kiểm tra sau gỡ: không đối tượng nào còn hạn (tổng 0), mọi default_..._ms là None; fact_items_part có expires và expiration_ms đều None.
 - Ôn Python cuối ngày: xong 6/6 (vòng for lồng nhau, update_dataset, get_table, if t.expires is not None, try/except, for _, row in df.iterrows()). Bài che code: viết lại bản kiểm tra chỉ đọc (Cell 7), sai list_tables thay vì get_table, Print viết hoa và hai lỗi chính tả, đã sửa.

- **Tuần 3, Ngày 2**: cài dbt, khởi tạo project, kết nối BigQuery.
  - **Cài đặt**: `pip install dbt-bigquery` trong môi trường `bi` (Anaconda Prompt) cài được `dbt-core` 1.12.5 và `dbt-bigquery` 1.12.1 (cả hai báo up to date). `protobuf` bị hạ từ 7.36.2 xuống 6.33.6 vì dbt cần bản cũ hơn; có cảnh báo vàng về thư mục tạm `google\~upb` (an toàn, có thể xóa tay). Đã kiểm tra: `pip check` báo `No broken requirements found`, import `google.cloud.bigquery` chạy được (3.45.2).
  - **Khởi tạo**: `dbt init bi_dbt` ở thư mục repo tạo `bi_dbt/` (`dbt_project.yml`, `models/example/`, `seeds/`, `snapshots/`, `macros/`, `analyses/`, `tests/`, `.gitignore`, `README.md`). Chọn adapter `bigquery`, xác thực `oauth`, project `bq-learning-510104`, dataset `dbt_dev`, threads 4.
  - **Hai chỗ phải sửa trong `profiles.yml`**: câu hỏi location là danh sách đánh số (`[1] US`, `[2] EU`), gõ `2` nên ra `EU`, đã sửa thành `US`; và `maximum_bytes_billed` mặc định là `None` nên tự thêm `1000000000`. Sau khi sửa, `dbt debug` hiện `location: US`, `maximum_bytes_billed: 1000000000` và `All checks passed!`.
  - **Kiểm tra trước khi commit**: `git status -uall` chỉ liệt kê file cấu hình và thư mục mẫu trong `bi_dbt/`, không có `logs/` hay `target/`, không có `profiles.yml` (nó nằm ngoài repo). Dataset `dbt_dev` chưa xuất hiện trong BigQuery: `dbt debug` không tạo dataset.
  - **Ôn Python cuối ngày**: xong 6/6 (`list_tables` khác `get_table`; hai dòng gán `= None` chỉ sửa bản sao và cần `update_dataset`; `for _, row in df.iterrows()`; khối `except` viết sai; vòng `for` lồng nhau 4 vòng ngoài và 19 vòng trong; `maximum_bytes_billed` trong `QueryJobConfig`).
  - **Checklist Excel**: xong việc cài dbt, khởi tạo, cấu hình kết nối; Tuần 3 là 2/7, tổng 25/61 (kiểm tra lại số hiển thị trong file).
  - **Tuần 3, Ngày 3**: khai báo source và viết staging model đầu tiên bằng dbt.
  - **Source**: `_thelook__sources.yml` khai báo nguồn `thelook` (`database: bigquery-public-data`, `schema: thelook_ecommerce`) với 4 bảng `order_items`, `orders`, `products`, `users`. Trong BigQuery, `database` của dbt là project, `schema` là dataset.
  - **Staging**: `stg_thelook__order_items.sql` (view) liệt kê từng cột, không dùng `SELECT *`: `order_item_id` (đổi từ `id`), `order_id`, `user_id`, `product_id`, `status`, `sale_price`, `created_at`, `order_date` (`date(created_at)`). Chưa có quy tắc nghiệp vụ; quy tắc "chỉ tính đơn Complete" sẽ nằm ở tầng mart.
  - **Chạy dbt**: `dbt compile` báo `Found 3 models, 4 data tests, 4 sources`; `dbt run --select stg_thelook__order_items` báo `CREATE VIEW (0 processed)`, `PASS=1`, 13,47 giây. dbt tự tạo dataset `dbt_dev` (US, Default table expiration = Never) khi chạy model đầu tiên.
  - **Đối chiếu số dòng**: view dbt có 181.466 dòng (2019-01-05 đến 2026-10-12), bảng `lab.fact_items_plain` có 180.771 dòng. Trong khoảng ngày của bảng lab (2019-01-11 đến 2026-10-04) view có 174.936 dòng, ngoài khoảng đó có 1 dòng trước và 6.529 dòng sau. Chênh theo năm đổi dấu (2025: -1.002; 2026: +1.763). Giả thuyết: bảng nguồn công khai được cập nhật sau khi chụp bản lab (chưa chứng minh).
  - **Kiểm tra notebook Tuần 1-2**: `# Cell 1` chạy được, `get_table` và `SELECT 1` qua `stats` chạy được sau khi `protobuf` bị hạ xuống 6.33.6.
  - **Checklist Excel**: bỏ tick dòng budget/quota (quota chưa làm), tick dòng cài dbt và dòng source + staging; Tuần 3 là 3/7, tổng 26/61 (kiểm tra lại số hiển thị).

  - **Tuần 3, Ngày 4**: mart model dùng `ref`.
  - **Staging mới**: `stg_thelook__products` (view): `product_id` (đổi từ `id`), `product_name`, `category`, `brand`, `department`, `cost`, `retail_price`.
  - **Mart** (`table`, trong `bi_dbt/models/marts/`): `dim_products` (từ `ref` staging products, 1 dòng = 1 sản phẩm, khoảng 29,1 nghìn dòng, quét 2,5 MiB) và `fct_net_sales` (grain: 1 mặt hàng trong 1 đơn `Complete`; `order_item_id`, `order_id`, `user_id`, `product_id`, `order_date`, `sale_price`, `cost`, `gross_profit = sale_price - cost`; `left join` sang products; quét 10,5 MiB). Quy tắc doanh thu `status = 'Complete'` nằm ở mart.
  - **`ref` và thứ tự chạy**: gõ lệnh với staging ở cuối nhưng dbt vẫn chạy staging trước (từ các `ref` dbt dựng sơ đồ phụ thuộc); hai table không phụ thuộc nhau chạy song song. `dbt run`: `PASS=3`, 33,51 giây. `dbt compile` chỉ dịch ra SQL thuần, không quét byte, không sửa file gốc.
  - **Kiểm tra bằng notebook** (số chạy ngày 10/10/2026): `fct_net_sales` 45.529 dòng = 45.529 `order_item_id` duy nhất (đúng grain), `cost` NULL = 0 (join không mất sản phẩm), bằng số dòng `Complete` của staging (45.529). Cùng phép tính trên view staging quét 3,16 MB, trên `fct_net_sales` quét 0,35 MB, cả hai billed 10 MB (mức tối thiểu); hai kết quả giống hệt nhau.
  - **Ôn Python cuối ngày**: xong 3 câu Python + 3 câu nội dung. Cần ôn: `use_query_cache=False` không xóa cache; `df` là dữ liệu trả về, byte lấy từ `job`.
  - **Checklist Excel**: xong việc mart model dùng `ref`; Tuần 3 là 4/7, tổng 27/61.

  - **Tuần 3, Ngày 5**: Power BI Desktop đọc bảng mart, tạo quan hệ.
  - **Kết nối**: Get data → Google BigQuery, Import mode, đọc `dbt_dev.fct_net_sales` và `dbt_dev.dim_products`.
  - **Quan hệ**: `fct_net_sales.product_id` (nhiều) → `dim_products.product_id` (một), Many to one, Single, active. Bộ lọc đi từ bảng một sang bảng nhiều. `dim_products` 29.120 dòng = 29.120 `product_id` duy nhất; `fct_net_sales` không có `product_id` lệch (0).
  - **Đối chiếu** (11/10/2026): SQL cho 45.529 dòng = 45.529 `order_item_id` duy nhất, doanh thu 2.685.271,28, lợi nhuận 1.391.199,0 (quét 1,04 MB, billed 10 MB). Power BI: Count 45.529; tổng bảng theo category 2.685.271,28; card lợi nhuận 1,39M (đã làm tròn). Tổng bảng category khớp card doanh thu.
  - **Làm mới số liệu**: `fct_net_sales` là bản chụp lúc `dbt run` cuối, Power BI là bản sao lúc Refresh cuối; muốn số mới thì `dbt run` rồi Refresh.
  - **Ôn Python cuối ngày**: xong 3 câu Python + 3 câu nội dung. Cần ôn: hướng lọc từ một sang nhiều (mình nói ngược), `job.result()` phải đứng trước khi đọc byte, `client` là kênh kết nối (không phải dbt), `location` phải khớp vùng dataset.
  - **Checklist Excel**: xong 2 việc (Power BI kết nối; quan hệ); Tuần 3 là 6/7, tổng 29/61.

- **Tuần 4, Ngày 1**: dbt test trên 2 mart.
  - **File test**: `bi_dbt/models/marts/_marts__models.yml`, 7 test: `dim_products.product_id` (`unique`, `not_null`), `dim_products.department` (`accepted_values`: `Women`, `Men`), `fct_net_sales.order_item_id` (`unique`, `not_null`), `fct_net_sales.product_id` (`not_null`, `relationships` sang `ref('dim_products')`). Khóa `data_tests:` và khối `arguments:` chạy được trên dbt 1.12.5, không thấy cảnh báo. `dbt test` báo `Found 6 models, 11 data tests` (4 test mẫu của `models/example/` + 7 test của mình).
  - **Cách test hoạt động**: dbt dựng mỗi test từ một mẫu SQL có sẵn, chạy trên BigQuery; câu SQL trả về các dòng SAI; 0 dòng là PASS, từ 1 dòng là FAIL (`Got N results, configured to fail if != 0`). `N` là số dòng kết quả của test, không phải số dòng của bảng.
  - **Giá trị thật của `department`** (kiểm bằng `GROUP BY` trước khi viết test): `Women` 15.989, `Men` 13.131, tổng 29.120 = số dòng `dim_products`, không có NULL.
  - **Cho test fail để xem**: `values: ['Women']` (cố ý thiếu `Men`) cho `FAIL 1`, `PASS=3 ERROR=1 TOTAL=4`; sửa thành `['Women', 'Men']` thì `PASS=4`. Cuối cùng cả 7 test đều đạt.
  - **Chọn model chạy theo test**: chọn `dim_products` thì dbt chạy luôn test `relationships` (nó đọc `dim_products`) nên số test lớn hơn dự kiến.
  - **Chưa làm / chưa đo**: chi phí thật của các lần `dbt test` (đã bỏ cell đo); chưa thử `client.list_jobs`.
  - **Ôn Python cuối ngày**: 3 câu Python + 3 câu nội dung. Cần ôn: `table_id` là tên bảng (không phải cột) và `list_rows` không dùng SQL; `df` là DataFrame trong bộ nhớ, byte lấy từ `job`; `* 1024 * 1024` đổi MB sang byte; `Got N results`; `relationships` chỉ tìm khóa của fact không có trong dimension; trần byte của dbt nằm ở `profiles.yml`.
  - **Checklist Excel**: xong việc "Viết test (unique, not_null, relationships)"; Tuần 4 là 1/7. Tổng số việc đổi từ 61 sang 69 (lộ trình mới), nên tổng là 30/69.

- **Tuần 4, Ngày 2**: dbt docs.
  - **Mô tả**: thêm `description` cho 2 mart (kèm grain và quy tắc `status = 'Complete'`), các cột và source `thelook` (4 bảng). `dim_products` có đúng 5 cột (`product_id`, `product_name`, `category`, `brand`, `department`), không có `cost` và `retail_price`. 7 test giữ nguyên (`dbt compile` báo `Found 6 models, 11 data tests, 4 sources`).
  - **Docs**: `dbt docs generate` đọc file dự án (miễn phí) rồi hỏi BigQuery lấy kiểu cột và số dòng; `dbt docs serve` chỉ mở file đã tạo. Trang docs: mô tả lấy từ yml, kiểu dữ liệu và số dòng lấy từ BigQuery (`INT64` là `INTEGER`); cột Description trong BigQuery vẫn là `-` (mô tả chỉ nằm trong dbt docs).
  - **Lineage**: mũi tên đến từ `source()` và `ref()` trong file SQL; yml khai báo và mô tả. `ref()` trong yml (như `relationships`) chỉ nối cái test với các bảng nó kiểm tra. Source `orders` và `users` đã khai báo nhưng chưa model nào dùng nên không có mũi tên. `models/example/` (2 model mẫu) cũng hiện thành một nhóm riêng.
  - **Đo chi phí**: xem mục 5.
  - **Ôn Python cuối ngày**: 3 câu Python + 3 câu nội dung. Cần ôn: `generate` hỏi BigQuery còn `serve` thì không; mũi tên lineage từ `source()` và `ref()` trong SQL; `dry_run` không đọc dữ liệu; `iterrows()` trả một cặp (số thứ tự, dòng).
  - **Ghi chú**: bạn tự đánh giá chỉ nắm khoảng 40% bài vì nhiều phần đào sâu đo chi phí; từ nay câu hỏi lệch mục đích ngày ghi vào mục 11 rồi làm sau.
  - **Checklist Excel**: tick "Viết test" (Ngày 1) và "Sinh tài liệu dbt docs"; Tuần 4 là 2/7, tổng 31/69.
  - **Tuần 4, Ngày 3**: incremental model.
  - **Model**: `fct_net_sales_inc` (cùng grain và cột với `fct_net_sales`, giữ nguyên `fct_net_sales` vì Power BI đang đọc). Lần đầu `CREATE TABLE` 45,3 nghìn dòng (10,5 MiB processed, 9,80 giây); lần hai `MERGE` 454 dòng (13,3 MiB processed, 4,39 giây). Bảng nhỏ nên incremental không rẻ hơn.
  - **Cơ chế**: dbt chỉ thêm điều kiện lọc rồi `MERGE` theo `unique_key`; không tự tìm dòng thay đổi. 454 là kích thước cửa sổ 3 ngày, tổng bảng không tăng (45.271 trước và sau).
  - **Nguồn công khai đổi mạnh**: `inc` 45.271 dòng khớp nguồn hiện tại; `fct_net_sales` (bản chụp 09/10) 45.529. Có 34.191 id chỉ ở bản cũ (trạng thái hiện tại: Shipped 13.871, Processing 8.871, Cancelled 6.770, Returned 4.576, không còn 103) và 33.933 id chỉ ở bản mới. Sau `MERGE`: thiếu 0, thừa 0 (chỉ đúng tại lúc chạy).
  - **Test**: `dbt test --select fct_net_sales_inc` `PASS=4 TOTAL=4`, `Found 7 models, 15 data tests, 4 sources`. Test không so với nguồn nên không bắt được đơn đổi sang `Returned` còn nằm lại trong bảng `inc`.
  - **Chi phí**: billed 30 MB cho truy vấn đọc 3 bảng, 20 MB cho 2 bảng; ủng hộ giả thuyết mức tối thiểu 10 MB tính theo từng bảng khác nhau. `dbt test` hôm nay chưa đo.
  - **Ôn Python cuối ngày**: 3 câu Python + 3 câu nội dung. Cần ôn: incremental không tự biết dòng nào đổi; cửa sổ là `max - 3 ngày`; 4 test không bắt được dòng đổi trạng thái; `client.query()` không chờ, `job.result()` mới chờ; `iterrows()` trả cặp.
  - **Checklist Excel**: xong việc "Viết incremental model"; Tuần 4 là 3/7, tổng 32/69.

  - **Tuần 4, Ngày 4**: measure và DAX cơ bản trong Power BI. Notebook `Python/Week 4/Day4.ipynb` (đối chiếu SQL).
  - **5 measure** trong bảng `fct_net_sales` (viết bằng New measure): `Net Revenue = SUM(sale_price)`, `Gross Profit = SUM(gross_profit)`, `Order Items = COUNTROWS(fct_net_sales)`, `Orders = DISTINCTCOUNT(order_id)`, `Gross Margin % = DIVIDE([Gross Profit], [Net Revenue])` (tổng chia tổng). Tương ứng SQL: SUM, COUNT(*), COUNT(DISTINCT), SAFE_DIVIDE.
  - **Đối chiếu SQL và Power BI** (mart là bản chụp Import, chưa Refresh): 45.529 order item, 31.335 đơn, doanh thu 2.685.271,28, lợi nhuận 1.391.199,0, biên 0,5181 (51,8%); billed 10 MB (processed 1,04 MB). Theo department (Cell 4, 2 bảng, billed 20 MB): Men 23.067 dòng, 1.427.482,26, lợi nhuận 738.332,74, 15.793 đơn, biên 51,7%; Women 22.462 dòng, 1.257.789,02, lợi nhuận 652.866,26, 15.542 đơn, biên 51,9%. Men + Women khớp tổng; slicer `dim_products[department]` làm bảng category và các Card đổi đúng.
  - **Implicit và explicit measure**: cùng số (kéo `sale_price` vào biểu đồ ra Sum 2.685.271,28), nhưng explicit gọi lại được trong measure khác, định nghĩa một chỗ, không bị đổi cách gộp nhầm (`Average of gross_profit` = 30,56 là lợi nhuận trung bình mỗi dòng, khác hẳn biên 51,8%).
  - **Filter context**: slicer lọc `dim_products` rồi bộ lọc đi qua quan hệ `product_id` từ một sang nhiều; ở dòng Total, Power BI tính lại measure với filter context rỗng, không cộng các dòng. Không có quan hệ thì mọi category hiện cùng tổng 2.685.271,28.
  - **Measure và calculated column**: column tính từng dòng của fact lúc Load/Refresh và lưu trong bảng; measure tính lúc hiển thị theo filter context. Tỷ lệ ở dòng Total phải là measure (tổng chia tổng), cột chốt tỷ lệ từng dòng rồi gộp lại thì mọi dòng nặng ngang nhau.
  - **Chưa làm**: sửa tên measure sai chính tả (`Goss Profit`, `Goss Margin %`, thẻ `Order`); `.pbix` chưa lưu ngoài repo nếu chưa lưu (kiểm tra).
  - **Ôn Python cuối ngày**: 2 câu Python + 3 câu nội dung. Cần ôn: tổng chia tổng khác trung bình các tỷ lệ (trọng số); `client.query()` không chờ, `job.result()` mới chờ, byte lấy từ `job`, `.to_dataframe()` đưa kết quả vào `df`; `maximum_bytes_billed` so với **billed** (không phải processed), vượt thì không tính tiền; xóa quan hệ thì mọi category cùng tổng, không báo lỗi; calculated column tính lúc Load, lưu trong bảng.
  - **Checklist Excel**: xong việc "Viết measure và DAX cơ bản"; Tuần 4 là 4/7, tổng 33/69.

    - **Tuần 4, Ngày 5**: thêm `dim_date` và chuẩn hóa star schema trong Power BI. Notebook `Python/Week 4/Day5.ipynb`.
  - **`dim_date`**: tạo bằng dbt (SQL thuần, `generate_date_array`), chạy `CREATE TABLE`, 3,3 nghìn dòng, 0 byte processed, 8,80 giây. 3.287 dòng = 3.287 ngày duy nhất, không NULL (9 năm × 365 + 2 năm nhuận). `month_number` và `weekday_number` có để Power BI sắp xếp tên tháng và thứ theo đúng thứ tự.
  - **Test**: `dbt test --select dim_date fct_net_sales` `PASS=7 TOTAL=7`; `dbt compile` báo `Found 8 models, 18 data tests, 4 sources` (15 test cũ + 2 của `dim_date` + 1 `relationships` mới).
  - **Đối chiếu** (cùng bản chụp mart, không Refresh `fct_net_sales`): `fct_net_sales` 45.529 dòng, 0 `order_date` không khớp `dim_date`, ngày đặt hàng từ 2019-01-27 đến 2026-10-14. Doanh thu theo năm khớp ma trận Power BI: 2019: 335 dòng, 17.837,11; 2020: 1.212, 71.756,66; 2021: 2.218, 133.658,87; 2022: 3.459, 202.062,04; 2023: 4.936, 290.075,70; 2024: 6.929, 406.979,98; 2025: 10.706, 624.117,64; 2026: 15.734, 938.783,28; tổng 2.685.271,28. Chọn Women: 1.257.789,02 và 22.462 dòng (khớp số Women Ngày 4). Chi phí: Cell 2 billed 10 MB (processed 0,03), Cell 3 billed 20 MB (0,37), Cell 4 billed 20 MB (0,74).
  - **Power BI**: mô hình có `dim_products` và `dim_date` cùng nối vào `fct_net_sales` (nhiều), Single. "One to many" và "Many to one" chỉ là hai cách đọc cùng một quan hệ, tùy bảng nào đứng bên From; cái cần đúng là phía "một" là dimension. Đã sửa tên measure sai chính tả (`Gross`), xóa thẻ implicit `Average of gross_profit`, tắt Auto date/time. Hộp thoại Mark as a date table ghi "not recommended" (chỉ cần cho một số mô hình như Excel PivotTable).
  - **Chưa xác nhận trong ảnh**: ẩn cột `order_date` của fact (lúc chụp chưa ẩn), sort `month_name` theo `month_number` và `weekday_name` theo `weekday_number`, đã bấm Save ở hộp thoại Mark as a date table chưa, đã lưu `.pbix` ngoài repo chưa.
  - **Chưa làm**: chưa có `dim_users` (source `users` đã khai báo, chưa có model).
  - **Ôn Python cuối ngày**: 3 câu Python + 3 câu nội dung. Cần ôn: `df = job.result().to_dataframe()` (dòng này chờ job rồi đưa kết quả vào DataFrame, không gửi job; `df` là DataFrame trong bộ nhớ, không phải table ở BigQuery; `df` chỉ chứa dòng kết quả, byte nằm ở `job`); `iterrows()` đưa ra cặp (nhãn, cả một dòng); `relationships` tìm giá trị CÓ trong fact nhưng KHÔNG có trong dimension (không phải NULL của fact); dòng không khớp hiện thành (Blank) trong ma trận, Total vẫn đủ nên không có lỗi đỏ; processed nhỏ vì query chỉ đọc cột cần (không phải vì bảng ít cột); bộ lọc đi một chiều từ dimension sang fact, fact là chỗ hai bộ lọc giao nhau (AND), không truyền bộ lọc giữa hai dimension.
  - **Checklist Excel**: xong việc "Chuẩn hóa mô hình star schema trong Power BI"; Tuần 4 là 5/7, tổng 34/69.
  - **Tuần 5, Ngày 1**: DAX `CALCULATE` và filter context, rồi chạy trọn vòng nguồn đến Power BI. Notebook `Python/Week 5/Day1.ipynb`.
  - **`CALCULATE`**: tính một biểu thức trong filter context đã bị sửa. Filter trong `CALCULATE` ghi đè filter cũ **trên cùng cột** (từ slicer hoặc từ dòng bảng); filter ở cột khác vẫn đi qua. `Net Revenue Men` hiện cùng số ở dòng Women vì `department = "Men"` thay `department = Women`; khi chọn 2024 nó chỉ là Men của 2024. `REMOVEFILTERS(dim_products)` chỉ gỡ filter đi từ `dim_products`, filter năm (từ `dim_date`) vẫn giữ, nên `Revenue % of Total` có mẫu số là tổng của năm đang chọn.
  - **Đối chiếu bản chụp cũ** (45.529 dòng, trước `dbt run`): Men 1.427.482,26; Women 1.257.789,02; 2025: 321.889,79 + 302.227,85 = 624.117,64; 2024: 216.353,37 + 190.626,61 = 406.979,98. Đều khớp SQL.
  - **Vòng đầu-cuối** (nguồn, `dbt run`, `dbt test`, SQL, Refresh, so số): đạt. Bản chụp mới: `fct_net_sales` 45.285 dòng = 45.285 `order_item_id`, doanh thu 2.707.334,88, lợi nhuận 1.405.850,55, ngày đặt từ 2019-01-21 đến 2026-10-22. Men 1.418.890,23; Women 1.288.444,65; 2025: 323.181,07 + 292.179,14 = 615.360,21; 2024: 215.360,70 + 190.932,61 = 406.293,31. Power BI sau Refresh khớp SQL.
  - **Nguồn public đổi**: doanh thu 2025 đổi từ 624.117,64 sang 615.360,21 dù là năm đã qua, nên tập đơn `Complete` của năm cũ vẫn thay đổi. `dbt test` báo 11/11 PASS vẫn không phát hiện, vì test kiểm cấu trúc chứ không đối chiếu với nguồn. Ngày đặt cuối 2026-10-22 nằm sau ngày hôm nay (19/10/2026), củng cố nhận định dữ liệu là mô phỏng. Chưa so id giữa hai bản chụp, nguyên nhân vẫn là giả thuyết.
  - **Ôn cuối ngày**: 5 câu (3 nội dung, 2 Python), bỏ câu thứ 6 vì đã nắm chắc. Câu 1 thiếu ý "filter ở cột khác vẫn đi qua" (đã bổ sung). Câu 3 đúng ý chính nhưng cần chính xác hơn: test không chỉ bắt NULL mà kiểm `unique`, `not_null`, `accepted_values`, `relationships`; `dbt run` PASS chỉ nghĩa là SQL chạy được.
  - **Checklist Excel**: tick việc "DAX: CALCULATE, filter context" của Tuần 5 (kiểm tra lại tên dòng và số tổng hiển thị trong file).
    - **Tuần 5, Ngày 2**: time intelligence trong Power BI (YTD, cùng kỳ, YoY). Notebook `Python/Week 5/Day2.ipynb`.
  - **Measure**: `ytd`, `ly`, `YoY %` (xem mục 4). Time intelligence vẫn là `CALCULATE` đổi tập ngày; `TOTALYTD` tính lại từ đầu ở mỗi ô; BLANK coi như 0 trong phép trừ nên YoY ra −100% ở tháng chưa có dữ liệu.
  - **Đối chiếu** (cùng bản chụp, không Refresh): 12 tháng của 2025 khớp Cell 2 ở cả 4 cột; Total 615.360,21, `ly` 406.293,31, YoY 51,46%. Năm 2026 sau khi sửa `ly` khớp Cell 3: Total `ly` 473.647,45 (cùng kỳ đến 22/10/2025), YoY 107,50%; riêng tháng 10 `ly` 37.273,31, YoY 383,57%.
  - **Ba chỗ sai âm thầm** đã gặp và sửa: YTD tháng 11-12/2026 vẫn hiện số; YoY −100% ở hai tháng đó; Total và tháng 10/2026 so với cả năm/cả tháng của 2025 thay vì cùng kỳ. Không có lỗi đỏ nào.
  - **Mark as date table**: bật hay tắt đều ra cùng số trên mô hình này (đã đóng câu hỏi mở).
  - **Ôn cuối ngày**: 6 câu (3 nội dung, 3 Python), không còn hỏi lại `check` (dry run) và `job.result()` vì đã đúng hai lần. Câu 2b: kết luận đúng nhưng nhầm `LastData` đổi theo slicer (thật ra luôn là 22/10/2026). Câu 3: nhầm `max_mb=100` là một job (thật ra là tham số mặc định) và nhầm tác dụng của thiếu `return df` (thật ra `df` = `None`, trần vẫn chạy). Câu 6: nhận ra cần kiểm tháng cuối đủ ngày và số ngày có dữ liệu; chưa nêu được lý do dbt không bắt lỗi là vì lỗi nằm ở tầng DAX.
  - **Checklist Excel**: tick việc time intelligence của Tuần 5 (mình chưa đọc được file nên bạn tự đối chiếu tên dòng và số tổng hiển thị).

  - **Tuần 5, Ngày 3**: thiết kế dashboard trong Power BI. Notebook `Python/Week 5/Day3.ipynb`.
  - **Dashboard**: trang `Overview` (xem mục 4). Đối chiếu năm 2026 (cùng bản chụp): doanh thu 982.813,17, lợi nhuận 510.954,59, biên 52,0%, 11.083 đơn, 295 ngày có dữ liệu, ngày cuối 22/10/2026; khớp Power BI. Top 10 category khớp SQL (tổng 671.156,85, khoảng 68,3% doanh thu).
  - **Hai lỗi sai âm thầm đã gặp và sửa**: `Avg Order Value` ra 61,00 thay vì 88,68 (nghi mẫu số là số dòng thay vì số đơn; sửa thành `DIVIDE([Net Revenue], [Orders])`); `Data Through` đổi thành 31/7/2026 khi bấm điểm 2026-07 (sửa bằng `REMOVEFILTERS` và Edit interactions). Cả hai không có lỗi đỏ; lỗi thứ nhất lộ nhờ Cell 3.
  - **Trả lời câu hỏi mở**: năm 2026 mỗi đơn chỉ thuộc một department (Orders Men 5.506 + Women 5.577 = 11.083); chưa kiểm các năm khác.
  - **Ôn cuối ngày**: 4 câu trả lời (câu 2 và câu 6 bỏ theo yêu cầu). Câu 1: đúng ý chính, thay "ghi đè" bằng "thu hẹp tập dòng". Câu 3: nhầm nguyên nhân và cách phát hiện (cần đối chiếu SQL độc lập). Câu 4 (`df.T`): đúng. Câu 5: đúng hướng, thiếu ý "danh sách đổi, không chỉ thứ tự".
  - **Checklist Excel**: tick việc thiết kế dashboard của Tuần 5 (mình chưa đọc được file nên bạn tự đối chiếu tên dòng và số tổng hiển thị).

    - **Tuần 5, Ngày 4**: tối ưu hiệu năng mô hình và báo cáo Power BI. Notebook `Python/Week 5/Day4.ipynb`.
  - **Số gốc** (Cell 3, 4): 45.285 dòng, 31.203 đơn, doanh thu 2.707.334,88, 2026 là 982.813,17, ngày cuối 2026-10-22. Số giá trị khác nhau: `order_item_id` 45.285, `order_id` 31.203, `user_id` 27.546, `product_id` 22.840, `cost` 21.071, `gross_profit` 21.079, `sale_price` 3.681, `order_date` 2.670.
  - **Kết quả**: `.pbix` 3.669.950 byte (3,50 MB) xuống 1.540.766 byte (1,47 MB) sau khi bỏ 4 cột không dùng; thẻ KPI năm 2026 vẫn khớp Cell 3. Performance Analyzer: `DAX query` luôn dưới khoảng 150 ms, `Visual display` khoảng 0,1 đến 3,8 giây, `Table` thường là biểu đồ chậm nhất; hai lượt đo cùng thao tác lệch nhau hàng nghìn ms, nên chưa kết luận gì về tốc độ trước và sau khi bỏ cột.
  - **Ẩn khác bỏ**: ẩn cột (Hide) chỉ giấu khỏi danh sách trường, dữ liệu vẫn nằm trong bảng Import và quan hệ, measure vẫn dùng được; bỏ cột ở Power Query thì cột không được nạp vào mô hình. Bỏ cột đang được dùng thì quan hệ hoặc measure báo lỗi.
  - **Không thấy Refresh trong `INFORMATION_SCHEMA.JOBS`**: hai khả năng (Power BI đọc qua đường khác không tạo job truy vấn, hoặc bộ lọc của mình chưa đúng); chưa biết byte Refresh.
  - **Ôn cuối ngày**: 6 câu (3 nội dung, 3 Python). Câu 2: vòng `for` chạy 0 lần, nhầm "tập rỗng" với "giá trị null". Câu 5 ý 2: chưa nêu được lý do không kết luận được tốc độ (nhiễu đo). Câu 6: không nhớ `r"""` và `\s`.
  - **Checklist Excel**: tick việc "Tối ưu hiệu năng mô hình và báo cáo" của Tuần 5.
    - **Tuần 5, Ngày 5**: khảo sát tuyển dụng, chốt hướng Project 2, thêm tiêu chí xong. (Ảnh, lineage, sơ đồ Mermaid, README Project 1: điền vào đây khi làm xong.)
  - **Khảo sát tuyển dụng**: 27 tin ở TP.HCM, 20 tin BI/Data Analyst và 7 tin Analytics/Data Engineer, lấy từ trang liệt kê (ITviec, Indeed, CareerViet, Glassdoor) và một số JD đầy đủ; LinkedIn và TopCV không truy cập được. Nhóm BI/DA: Power BI 17/20, Tableau 9/20, Looker 4/20. dbt 6/7 và BigQuery 4/7 chỉ ở tin kỹ sư; Airflow 3/7; Docker 0/27. Truy vấn đầu chứa "Power BI" nên số Power BI bị thổi phồng.
  - **Logistics và e-commerce có tin cụ thể**: GHN (2 tin, 2 đến 4 năm kinh nghiệm, ưu tiên logistics hoặc e-commerce), Tân Cảng Sài Gòn, Tiki (SnOP eLogistics), công ty tiếp vận, CyberLogitec, Wecare.
  - **ETL và ELT**: ETL biến đổi trước khi nạp, ELT nạp thô rồi biến đổi trong warehouse. Pipeline thời tiết là ETL, dbt trên BigQuery là ELT.
  - **Giấy phép**: bộ Olist là CC BY-NC-SA 4.0 (ghi nguồn, không thương mại, cùng giấy phép cho sản phẩm phái sinh).
  - **Tiêu chí xong**: 6 tiêu chí cho Project 1, thêm tiêu chí 7 (chạy theo lịch, log, mã thoát) và 8 (ghi nguồn và giấy phép) cho Project 2. Chi tiết ở mục 10.
  - **Ôn Python cuối ngày**: gộp vào ôn Ngày 6.
  - **Checklist Excel**: chưa đọc được file nên bạn tự tick việc Tuần 5 tương ứng (hoàn thiện Project 1, chốt ngách và dữ liệu) khi xong và đối chiếu số hiển thị.
  - **Tuần 5, Ngày 6**: đóng Project 1 và xác nhận dữ liệu Project 2. Không có notebook mới.
  - **Project 1 xong**: `dbt test` 4 mart `PASS=14 TOTAL=14`; thẻ KPI khớp SQL; star schema 2 quan hệ Single; cầu chì ghi trong README; README đủ mục (sơ đồ Architecture và Data model nằm trong phần Project 1, 3 ảnh trong `Doc/`); repo không có bí mật, `.pbix`, `data/`. `Doc/Definition_of_done.md` tích đủ 6 mục.
  - **Quét bí mật**: `git grep` ra 2 dòng đều an toàn (`.env.example` chữ giữ chỗ, `Day4.ipynb` dùng `os.getenv`). Chỉ quét bản hiện tại. Lần này push trước khi quét xong; từ nay quét trước khi push.
  - **Dữ liệu Project 2**: xác nhận thư mục Olist ở `D:\BI\projects\ai-logistics\data\olist` (9 file). `D:\BI\Dataset` không phải Olist.
  - **Ôn cuối ngày**: 6 câu (3 Python, 3 nội dung). Đúng: `CALCULATE` ghi đè filter cùng cột; ETL và ELT. Cần ôn: `for` với `df` rỗng chạy 0 lần; `def` chỉ định nghĩa, thiếu `return` thì `None`; chữ `r` ngoài là Python còn chữ `r` trong SQL là BigQuery; `relationships` tìm khóa mồ côi, không phải NULL.
  - **Checklist Excel**: tick việc hoàn thiện Project 1 của Tuần 5 (kiểm tra lại tên dòng và số tổng hiển thị).

  - **Tuần 6, Ngày 1**: tạo repo `olist-bi-project`.
  - **Repo**: tạo trên GitHub (Public, README, `.gitignore` Python, không chọn License), clone về `D:\BI\projects\olist-bi-project`. Thêm khối luật vào `.gitignore` trước khi có file dữ liệu. `git check-ignore -v` xác nhận bị chặn: `.env` (dòng 224), `data/` (dòng 225), `*.pbix` (dòng 229).
  - **README khởi đầu** (tiếng Anh): mục tiêu, nguồn dữ liệu (Brazilian E-Commerce Public Dataset by Olist), giấy phép CC BY-NC-SA 4.0, ghi rõ dữ liệu không nằm trong repo và dự án chỉ để học và portfolio, không dùng cho khách trả tiền (tiêu chí 8).
  - **Notebook** `Notebook/Week01/Day1.ipynb`: đọc `OLIST_DIR` từ `.env` bằng `python-dotenv`, liệt kê file `.csv`, đọc tiêu đề bằng `pd.read_csv(f, nrows=0)`. Kết quả: 9 file, tổng khoảng 120 MB (lớn nhất `geolocation` 58,44 MB; nhỏ nhất `product_category_name_translation` khoảng 0 MB). Số cột: customers 5, geolocation 5, order_items 7, order_payments 5, order_reviews 7, orders 8, products 9, sellers 4, translation 2. Chưa thấy trọn tên cột của `orders` (cột thứ 8) và `products` (cột thứ 9) vì ảnh bị cắt.
  - **Commit**: 3 commit trên GitHub (1 của GitHub, 2 của mình): `Add project skeleton: README, .gitignore rules, .env.example` và `Add Day 1 notebook: list Olist files and columns`. Không có `.env` trên GitHub.
  - **Chi phí**: không đụng BigQuery nên không tốn byte.
  - **Ôn cuối ngày**: 6 câu (3 Python, 3 nội dung). Đúng ý chính: `nrows=0` chỉ đọc tiêu đề; `files` rỗng thì vòng `for` chạy 0 lần; `.gitignore` thêm sau không gỡ được file đã lên GitHub. Cần ôn: `.tolist()` đổi sang list; mốc quyết định là `git add`/`commit`, lịch sử vẫn giữ file; `print(len(files))` đứng trước vòng `for` để bắt trường hợp rỗng; `git grep --cached` không quét lịch sử và chỉ quét 4 mẫu (không liên quan `.env`); `os.getenv` đọc biến môi trường, `load_dotenv` mới đọc file `.env`, `""` là giá trị mặc định; CC BY-NC-SA: BY ghi nguồn, NC không thương mại, SA cùng giấy phép; không đưa dữ liệu lên GitHub là quyết định thận trọng.
  
  - **Checklist Excel**: tick việc tạo repo Project 2 của Tuần 6 (kiểm tra lại tên dòng và số tổng hiển thị).

  - **Tuần 6, Ngày 2**: khám phá 9 file Olist (tên cột, grain, khóa nối, khoảng ngày). Notebook `Notebook/Week02/Day2.ipynb` trong repo `olist-bi-project` (sửa lại nếu bạn đặt tên khác).
  - **Đã làm**: đọc 9 file vào pandas (`dtype=str`), kiểm khóa dự đoán, khóa nối con tìm cha, khoảng ngày. Không đụng BigQuery nên không tốn byte.
  - **Số dòng và grain** (khớp Ngày 1 ở số cột): `customers` 99.441 (`customer_id`), `orders` 99.441 (`order_id`), `items` 112.650 (`order_id` + `order_item_id`), `payments` 103.886 (`order_id` + `payment_sequential`), `reviews` 99.224 (`review_id` trùng 814; `review_id` + `order_id` trùng 0), `products` 32.951, `sellers` 3.095, `translation` 71, `geolocation` 1.000.163 (zip trùng 981.148, còn khoảng 19.015 zip khác nhau, không có khóa tự nhiên theo zip).
  - **Khóa nối**: 6 mối nối con tìm cha đều NULL 0, mồ côi 0 (`items` sang `orders`, `products`, `sellers`; `orders` sang `customers`; `payments` và `reviews` sang `orders`). Ngoại lệ: `products.product_category_name` sang `translation` có NULL 610 và mồ côi 13 (13 là số dòng sản phẩm, chưa biết mấy category). Chưa kiểm chiều ngược (đơn không có mặt hàng).
  - **Khoảng ngày**: `orders` từ 2016-09-04 đến 2018-10-17, 0 ngày không đọc được; thưa ở cuối 2016 (không có 2016-11), dày từ 2017-01, 2018-10 là tháng dở. Danh sách `order_status` đầy đủ chưa xem (output bị cắt, chỉ thấy `processing` 301, `created` 5, `approved` 2).
  - **Kết luận**: Olist là bản chụp lịch sử, không tự cập nhật; "cập nhật tự động" của Project 2 sẽ mô phỏng bằng cách nạp từng khối tháng theo `order_purchase_timestamp`.
  - **Ôn cuối ngày**: 6 câu (3 Python, 3 nội dung). Đúng: `errors="coerce"`, ví dụ nhân dòng khi nối (khách A 300 thay vì 100). Cần ôn: `isin` trả dãy True/False dài bằng bảng con; 610 là NULL trong `products`, 13 là mồ côi; code vẫn chạy tiếp Bước 3 khi `missing_cols` rỗng; cột chia thời gian là `order_purchase_timestamp`.
  - **Checklist Excel**: tick việc khám phá dữ liệu Olist của Tuần 6 nếu có (mình chưa đọc được file nên bạn tự đối chiếu tên dòng và số tổng hiển thị).

  - **Tuần 6, Ngày 3**: nạp bảng đầu tiên vào `olist_raw`. Notebook `Notebook/Week03/Day3.ipynb`.
  - **Quyết định**: raw toàn STRING, ép kiểu bằng `SAFE_CAST` ở dbt staging (ELT). Lý do: giữ số 0 đầu của mã zip (BigQuery tự đoán kiểu có thể đổi cột toàn chữ số thành số), ngày hỏng không làm cả load job thất bại, raw giữ nguyên dữ liệu gốc.
  - **Đã làm**: Cell 1 đọc `.env`, tạo `client` (9 file CSV, location US); Cell 2 tạo `olist_raw` (US); Cell 3 nạp `product_category_name_translation.csv` thành bảng `olist_raw.product_category_translation`: 71 dòng, 2 cột; Cell 4 đối chiếu: `num_rows` 71, `COUNT(*)` 71, `COUNT(DISTINCT product_category_name)` 71, hai cột STRING, billed 10 MB.
  - **Ôn cuối ngày**: 6 câu (3 Python, 3 nội dung). Đúng: file được đóng sau khối `with`; `nrows=0` rồi `.tolist()`; `cfg` chỉ là cấu hình; thiếu `skip_leading_rows` thì tiêu đề lẫn vào dữ liệu (72 dòng); join thường làm mất 623 sản phẩm không có tên tiếng Anh. Cần ôn: `job.result()` chỉ chờ, không gán gì vào `job`; NULL (ô category trống) khác mồ côi (có tên nhưng `translation` không có); lý do ELT còn có "giữ số 0 đầu" và staging dùng `SAFE_CAST` rồi đếm NULL; `WRITE_APPEND` chạy 2 lần ra 142 dòng (không phải 141); `len(df)` là số dòng kết quả SQL (1), số dòng bảng là `t.num_rows` hoặc ô `so_dong`; nguồn độc lập để đối chiếu số dòng là chính file CSV.

    - **Tuần 6, Ngày 4**: nạp 8 bảng Olist còn lại vào `olist_raw`. Notebook `Notebook/Week04/Day4.ipynb`.
  - **Quyết định**: tên bảng raw bỏ `olist_` và `_dataset` (`customers`, `geolocation`, `order_items`, `order_payments`, `order_reviews`, `orders`, `products`, `sellers`), giống cách đặt `product_category_translation`.
  - **Đã làm**: vòng lặp gọi `load_csv_as_string`, mỗi bảng đối chiếu 4 số dòng. Kết quả cả 8 bảng `OK`, hai lần chạy (lần hai thử idempotent): customers 99.441, geolocation 1.000.163, order_items 112.650, order_payments 103.886, order_reviews 99.224, orders 99.441, products 32.951, sellers 3.095. Cả 8 bảng đúng số cột và kiểu STRING; hai chỗ trống từ Ngày 1 đã điền: cột thứ 8 của `orders` là `order_estimated_delivery_date`, cột thứ 9 của `products` là `product_width_cm`.
  - **Tên cột thật**: `customers` (`customer_id`, `customer_unique_id`, `customer_zip_code_prefix`, `customer_city`, `customer_state`); `geolocation` (`geolocation_zip_code_prefix`, `geolocation_lat`, `geolocation_lng`, `geolocation_city`, `geolocation_state`); `order_items` (`order_id`, `order_item_id`, `product_id`, `seller_id`, `shipping_limit_date`, `price`, `freight_value`); `order_payments` (`order_id`, `payment_sequential`, `payment_type`, `payment_installments`, `payment_value`); `order_reviews` (`review_id`, `order_id`, `review_score`, `review_comment_title`, `review_comment_message`, `review_creation_date`, `review_answer_timestamp`); `orders` (`order_id`, `customer_id`, `order_status`, `order_purchase_timestamp`, `order_approved_at`, `order_delivered_carrier_date`, `order_delivered_customer_date`, `order_estimated_delivery_date`); `products` (`product_id`, `product_category_name`, `product_name_lenght`, `product_description_lenght`, `product_photos_qty`, `product_weight_g`, `product_length_cm`, `product_height_cm`, `product_width_cm`; hai cột `lenght` sai chính tả ngay từ nguồn); `sellers` (`seller_id`, `seller_zip_code_prefix`, `seller_city`, `seller_state`).
  - **Kiểm `order_reviews`** (Cell 5): 99.224 dòng khớp file; 3.852 ô `review_comment_message` có chữ xuống dòng, nạp nguyên vẹn (`allow_quoted_newlines=True` hoạt động); 58.247 ô NULL, 0 chuỗi rỗng (ô trống thành NULL, mới kiểm cột này).
  - **Kiểm mã zip** (Cell 5b): `customers`, `sellers`, `geolocation` đều chỉ có độ dài 5 (dự đoán độ dài 4 là sai); raw giữ nguyên, staging chưa cần `LPAD`. Suy ra từ độ dài, chưa đếm trực tiếp zip bắt đầu bằng `'0'`.
  - **Lỗi gặp**: gõ `bigquery.schemaField` thay vì `SchemaField`; khối `try/except` bắt lỗi nên cả 8 bảng in `LỖI`, cell vẫn xanh, chưa bảng nào được nạp.
  - **Ôn cuối ngày**: 6 câu (3 Python, 3 nội dung). Đúng ý chính: `job.result()` chờ job; ví dụ mất số 0 đầu của zip; `except` cho vòng `for` đi tiếp; định nghĩa NULL và mồ côi. Cần ôn: bỏ `job.result()` thì `output_rows` thường là `None` (chưa thử), không phải lỗi đỏ; `len(df)` là số dòng kết quả SQL (1), `99224` là giá trị trong ô `so_dong`; `n_tbl` là `num_rows` của bảng BigQuery, không phải của pandas; `n_job` và `n_tbl` cùng phía BigQuery nên cùng sai thì vẫn bằng nhau, cần nguồn ngoài (`n_csv`); `join` thường làm mất 623 sản phẩm (610 NULL + 13 mồ côi), `left join` giữ lại nhưng tên tiếng Anh NULL; `print(len(TABLES))` đếm số bảng dự định, bắt trường hợp dictionary rỗng.
  - **Chi phí**: xem mục 5.
  - **Checklist Excel**: mình chưa đọc được file nên bạn tự đối chiếu: tick việc nạp dữ liệu Olist vào BigQuery của Tuần 6 nếu có (kiểm tra lại tên dòng và số tổng hiển thị).

    - **Tuần 6, Ngày 5**: dbt cho Project 2, staging `orders`. Notebook `Notebook/Week01/Day05.ipynb`.
  - **Quyết định**: thư mục dbt `olist_dbt/`, dataset `olist_dbt_dev` (US), tách khỏi `dbt_dev`. Cột ngày của staging đổi tên dạng `..._at` (`purchased_at`, `approved_at`, `delivered_to_carrier_at`, `delivered_to_customer_at`, `estimated_delivery_at`).
  - **Đã làm**: `dbt init`, cầu chì 1 GB trong `profiles.yml`, xóa `models/example/`, khai báo source `olist` (9 bảng), viết `stg_olist__orders` (view), thêm 2 test. `dbt test` `PASS=2 TOTAL=2`, `Found 1 model, 2 data tests, 9 sources`.
  - **Đối chiếu**: NULL trước và sau `SAFE_CAST` bằng nhau ở cả 5 cột (0, 160, 1.783, 2.965, 0); view 99.441 dòng = 99.441 `order_id` duy nhất, ngày 2016-09-04 đến 2018-10-17, `purchased_at` NULL 0; `order_status` 8 giá trị (delivered 96.478, shipped 1.107, canceled 625, unavailable 609, invoiced 314, processing 301, created 5, approved 2).
  - **Git**: commit `b10e6c1` (13 file, gồm sửa `.gitignore`) đã push; `git grep ... HEAD` không in dòng nào, `working tree clean`. Lần này push trước khi quét bí mật xong.
  - **Lỗi gặp**: luật `olist/` trong `.gitignore` (dòng 226) chặn `olist_dbt/models/staging/olist/` nên ba file chính không hiện trong `git status` (xem mục 9).
  - **Ôn cuối ngày**: 4 câu (2 Python, 2 nội dung), đều đúng ý chính. Cần ôn: `len(df)` là số dòng kết quả SQL; ví dụ cho "test không bắt được" phải gắn với cột đã được test.
  - **Checklist Excel**: mình chưa đọc được file nên bạn tự tick việc dbt cho Project 2 (nếu có) và đối chiếu số hiển thị.

## 8. Đang làm

- **Tuần 3** còn 1 việc: quota (chờ nâng cấp trả phí, quyết định trước 15/12/2026).
- **Tuần 6, Ngày 1 và Ngày 2**: xong (repo `olist-bi-project`; khám phá 9 file Olist).
- **Tuần 6, Ngày 3**: xong (`olist_raw`, bảng `product_category_translation` 71 dòng).
- **Tuần 6, Ngày 4**: xong (8 bảng trong `olist_raw`, số dòng khớp).
- **Tuần 6, Ngày 5**: xong (`olist_dbt/`, `stg_olist__orders`, `PASS=2`).
- **Tuần 6, Ngày 6** (tiếp theo, đề xuất): viết staging cho các bảng còn lại (ít nhất `order_items`, `order_payments`, `order_reviews`, `customers`, `products`, `product_category_translation`; `geolocation` cần quyết cách gom một dòng một zip), thêm test (`accepted_values` cho `order_status` với 8 giá trị đã biết, `relationships` cho khóa nối). Dòng vàng `models.olist_dbt.marts` sẽ hết khi có thư mục `models/marts/`.
## 9. Lỗi đã gặp và cách sửa

- **403 Forbidden khi chạy query từ Python**: đăng nhập nhầm tài khoản Google. Sửa: `gcloud auth application-default revoke`, đăng nhập lại đúng tài khoản, rồi `gcloud auth application-default set-quota-project bq-learning-510104`.
- **Gõ nhầm `git config user.mail`** thay vì `user.email`: Git không báo lỗi, khóa sai vô tác dụng. Sửa: đặt lại `user.email` và `--unset user.mail`.
- **Commit hiển thị sai tác giả trên GitHub**: email trong Git thuộc một tài khoản GitHub khác. Sửa: dùng email noreply của tài khoản đang dùng.
- **Cảnh báo "BigQuery Storage module not found"**: chỉ là cảnh báo. Muốn tải nhanh hơn với bảng lớn: `pip install google-cloud-bigquery-storage`.
- **Hộp thoại "No Python found" trong VS Code**: chọn Don't ask again, không cài Python qua uv vì đã có Anaconda.
- **Sửa SQL trong cell nhưng kết quả vẫn là của câu cũ, hoặc `NameError: name 'check' is not defined`**: sửa code xong phải chạy lại đúng cell đó thì biến hoặc hàm mới được cập nhật. Nhìn số thứ tự bên trái cell và tên cột của bảng kết quả để biết mình đang xem kết quả cũ hay mới. Tương tự trong Ngày 3: `NameError` với `r`, `params`, `get_json`... nghĩa là chưa chạy cell định nghĩa chúng.
- **`check(sql)` không tạo bảng**: `check` chỉ là dry run. Với câu `CREATE ... AS SELECT` phải chạy `run(sql)` thì bảng mới có, nếu không các truy vấn sau báo `Not found: Table ...`.
- **`BadRequest` khi chạy SQL trong notebook**: lỗi chi tiết nằm ở dòng cuối của thông báo, cần kéo xuống đọc. Các lỗi gõ đã gặp: `form` thay vì `from`, `deparment` thay vì `department`, thiếu dấu nháy quanh `'%Y%m%d'`, thừa dấu ngoặc, và sai tên cột khóa của bảng nguồn (`products` dùng `id`, không phải `product_id`).
- **`%y` thay vì `%Y` trong `FORMAT_DATE`**: không báo lỗi nhưng `date_key` ra dạng `250312` thay vì `20250312`, làm fact không nối được `dim_date`. Luôn kiểm tra `MIN(date_key)` sau khi tạo.
- **Test grain `COUNT(*) = COUNT(DISTINCT id)` không bắt được dòng bị mất do JOIN**: phải so thêm số dòng với bảng nguồn. Khi kiểm tra khóa nối bằng `LEFT JOIN`, phải thêm `WHERE dim.key IS NULL` hoặc `COUNTIF(... IS NULL)`, nếu chỉ đếm tổng thì luôn ra đủ số dòng.
- **Không thấy dòng "This query will process X" trong VS Code**: dòng này chỉ có trên giao diện web BigQuery. Trong notebook dùng `check(sql)`.
- **Commit trong VS Code mở tab `COMMIT_EDITMSG`**: gõ nội dung commit ở dòng 1, Ctrl+S rồi đóng tab thì commit mới hoàn tất. Để dòng 1 trống thì commit bị hủy. Sau đó bấm Sync Changes để push (có thể đang có commit cũ chưa push).
- **`cd` sang ổ đĩa khác không đổi thư mục (hoặc gõ `cd d: "..."` báo "syntax is incorrect")**: dùng `cd /d "D:\..."` (có `/d`, không có dấu hai chấm sau `cd`).
- **`ImportError: cannot import name 'path' from 'pathlib'`**: Python phân biệt hoa/thường, tên đúng là `Path` (P hoa).
- **Parquet lớn hơn CSV với bảng nhỏ (21 dòng)**: bình thường vì Parquet có phần tiêu đề cố định; không ghi "Parquet luôn nhỏ hơn". Lý do chọn Parquet là giữ đúng kiểu dữ liệu.
- **Pandas bản mới hiển thị kiểu chữ là `str` thay vì `object`**: không phải lỗi, chỉ là cách gọi tên.
- **Ghi `.gitignore` bằng `echo ... >> .gitignore` trên PowerShell** có thể ghi sai mã hóa làm Git bỏ qua dòng đó: gõ trực tiếp trong VS Code. Nếu một thư mục đã từng được commit thì thêm vào `.gitignore` không gỡ được nó khỏi lịch sử.
- **Gõ lệnh bị sai chữ do bộ gõ tiếng Việt** (`day4` thành `dãy`): tắt bộ gõ tiếng Việt khi gõ lệnh, tên nhánh, tên file. Đổi tên nhánh: `git branch -m <tên mới>`.
- **`NameError: name 'pd' is not defined`**: kernel đã khởi động lại nên biến mất, chạy lại các cell định nghĩa (cell import và cell kết nối).
- **`FutureWarning` về `pandas-gbq`** khi nạp DataFrame: chỉ là cảnh báo, dữ liệu vẫn nạp đủ. Chưa cài `pandas-gbq` (nếu cài: `%pip install pandas-gbq` trong notebook rồi restart kernel).
- **`git switch` báo "Deletion of directory failed"**: Windows không xóa được thư mục rỗng do VS Code đang giữ; trả lời `n`, rồi `git pull` để file về lại.
- **Cảnh báo `LF will be replaced by CRLF`** khi `git add`: chỉ là cảnh báo về ký tự xuống dòng trên Windows, bỏ qua được.
- **`.gitignore` chặn theo tên chính xác**: `test.env` vẫn lọt, chỉ `.env` bị chặn.
- **Terminal VS Code dùng Python của `base`, không phải `bi`** (`sys.executable` không có `envs\bi`): cài gói bằng `%pip install ...` trong notebook để vào đúng môi trường của kernel.
- **Gõ sai `sys.excutable`**: tên đúng là `sys.executable`.
- **`ModuleNotFoundError: No module named 'google.cloud'` khi chạy script**: lệnh `python` trong terminal VS Code dùng môi trường `base`. Chạy bằng đường dẫn đầy đủ tới Python của `bi` (`...\envs\bi\python.exe`) hoặc dùng Anaconda Prompt sau `conda activate bi`.
- **`ReadTimeout` khi gọi API**: lỗi mạng tạm thời, không phải lỗi code; `get_json` tự chờ và gọi lại (xem log `Lần 1/4`).
- **Log trong notebook không hiện hoặc không đổi mức**: thêm `force=True` vào `logging.basicConfig` vì notebook thường đã có sẵn cấu hình log.
- **`INFORMATION_SCHEMA.JOBS` trả về bảng rỗng**: bộ lọc thời gian quá hẹp (3 giờ) trong khi các query chạy cách đó hơn 5 giờ; cột thời gian là UTC. Sửa: nới lên 24 giờ. Khi gặp bảng rỗng, nới lần lượt từng điều kiện lọc để biết điều kiện nào loại mất dữ liệu.
- **Vòng `for` không in gì, cell vẫn chạy xong không lỗi** (Cell 14 Tuần 2): DataFrame rỗng (lọc `INTERVAL 1 HOUR` quá hẹp) nên vòng lặp chạy 0 lần; dấu hiệu là `processed: 0.0 MB`. Sửa: nới lên 24 giờ, và in `len(df)` trước khi lặp.
- **`TypeError` với `row["query"]`**: vòng lặp chỉ có một tên biến (`for row in df.iterrows()`) nên `row` nhận cả cặp (số thứ tự, dữ liệu dòng). Viết `for _, row in df.iterrows():` (và gõ đúng `iterrows`).
- **Đọc số byte khi job chưa xong ra `None`/0**: gọi `job.result()` trước khi đọc `total_bytes_processed`; hàm `mb` trả `None` để lỗi lộ ra.
- **Giá trị trạng thái gõ theo trí nhớ**: `Shipping` trong ghi chú nhưng dữ liệu thật là `Shipped`. Luôn `GROUP BY` xem giá trị thật trước khi viết `WHERE`.
- **Dashboard Data Studio: số trên thẻ không đổi khi lọc ngày**: không phải lỗi, các thẻ cập nhật chậm hơn biểu đồ (từng thẻ một); kiểm tra bằng SQL. Thẻ lệch tổng còn có thể do cross-filtering (bấm lại điểm trên biểu đồ hoặc Reset).
- **Biểu đồ trục `Month` chỉ có 12 điểm Jan đến Dec**: đó là tháng trong năm (các năm cộng dồn); chọn Year Month để có đường theo thời gian.
- **Giao diện Data Studio tiếng Việt**: mở `https://datastudio.google.com/?hl=en` trong tab mới.
- Bảng partition mất dữ liệu cũ: hạn partition 60 ngày của sandbox xóa các tháng cũ. Thứ tự đúng: gỡ hạn ở 3 tầng trước, tạo lại bảng sau, nếu không bảng mới thừa hưởng hạn.
- Except Exception nuốt lỗi: cell vẫn chạy xong không đỏ. Sau khi chạy phải tự đọc output tìm chữ LỖI.
- list_tables khác get_table: list_tables(dataset) trả danh sách tóm tắt (chưa có expires); get_table(bảng) trả thông tin đầy đủ.
- Print viết hoa (đúng là print): Python phân biệt hoa thường; nằm trong except thì cell dừng luôn.
- Gán = None trên ds hoặc t chưa đổi gì trên cloud: phải gọi update_dataset hoặc update_table.
- **Chọn nhầm location khi `dbt init` (`EU` thay vì `US`)**: câu hỏi là danh sách đánh số, gõ `2` ra `EU`. Dataset `lab`/`dwh`/`raw` ở US và BigQuery không nối chéo vùng. Sửa `location: US` trong `profiles.yml` rồi `dbt debug`; luôn đọc dòng `location:` trong output.
- **`dbt init` không đặt `maximum_bytes_billed`** (hiện `None`): tự thêm vào `profiles.yml`, số nguyên viết liền (không dùng phép nhân như trong Python).
- **Lệnh `python -c "..."` bị ngắt dòng** báo `'protobuf'' is not recognized...`: gõ liền trên một dòng.
- **Cảnh báo vàng `Failed to remove contents in a temporary directory ...\~upb`** khi cài dbt: thư mục tạm khi pip gỡ `protobuf` cũ, không phải lỗi; `pip check` xác nhận không xung đột.
- **Lỗi chính tả hoặc chữ hoa trong khối `except`** (`Print`, `talble_id`): chỉ nổ khi có bảng thật sự lỗi, và vì không còn `try` nào bắt nên cell dừng. Thử khối `except` bằng một tên bảng sai cố ý.
- **File `.yml` mở bằng Explorer thành `.yml.txt`**: Windows ẩn đuôi file đã biết, cột Type ghi "Text Document" là dấu hiệu. Tạo file bằng VS Code (New File, gõ tên có đuôi), hoặc bật View → Show → File name extensions; sửa bằng `move` đổi tên trong Anaconda Prompt.
- **File `.yml` đặt ngoài `bi_dbt/models/`**: dbt không đọc. Mọi file source và model phải nằm trong `models/`.
- **Anaconda Prompt hiện chữ vỡ khi `type` file tiếng Việt**: chỉ là cách hiển thị (mã hóa), nội dung file vẫn đúng; mở bằng VS Code hoặc `chcp 65001`.
- **Chạy `dbt compile` mà file trong `models/` không đổi**: đúng thiết kế, dbt không sửa file gốc (vẫn còn `{{ ref(...) }}`). Bản đã dịch hiện ở cửa sổ lệnh và lưu trong `bi_dbt\target\compiled\`; `target\` do dbt tự tạo, không commit.
- **Nhầm `df` với `job` trong hàm `stats`**: `df` chứa kết quả của câu SQL; số byte (`processed`, `billed`) lấy từ `job`, không nằm trong `df`.
- **Ngày trong Power BI hiện dạng `Wednesday, November 5, 2025`**: không phải lỗi, chỉ là định dạng hiển thị; đổi ở Column tools → Format.
- **Cột số thực (FLOAT) hiện nhiều chữ số lẻ trong Power BI** (`8.77499999478459`): sai số nhỏ của kiểu số thực, không phải lỗi; đặt hiển thị 2 chữ số thập phân và so sánh sau khi làm tròn.
- **Card Power BI hiện `45.529K` và `1.39M`**: đã làm tròn để hiển thị; muốn so từng chữ số, đặt Display units = None.
- **Hộp thoại đăng nhập BigQuery có hai tab**: chọn Organizational account (đăng nhập Google qua trình duyệt); Service Account Login cần file khóa JSON nên không dùng.
- **Gõ sai tên model sau `--select` (`dim_product` thiếu `s`)**: không có lỗi đỏ. dbt chỉ in dòng vàng `[WARNING]: The selection criterion ... does not match any enabled nodes`, chạy phần còn lại và kết thúc `Completed successfully`; test của model gõ sai không chạy (`TOTAL=4` thay vì 6). Luôn đọc dòng vàng và so `TOTAL` với số test mong đợi. Lệnh `dir` tìm file SQL của test báo `File Not Found` vì test chưa chạy nên file chưa được tạo.
- **Gõ `dbt --test select ...`**: lỗi `No such option '--test'`. Đúng là `dbt test --select ...` (lệnh không có gạch, tùy chọn có `--`).
- **Test fail không phải lỗi SQL**: `FAIL 1` + `Got 1 result` nghĩa là SQL chạy tốt nhưng trả về dòng sai (ở đây là một giá trị `department` không có trong danh sách).
- **`client.list_rows` trên `INFORMATION_SCHEMA.JOBS` báo `NotFound`**: đó là view hệ thống, không phải bảng lưu dữ liệu; `list_rows` gọi `get_table` trước nên không tìm ra. `list_rows` chỉ dùng cho bảng thật. SQL thì đọc được view hệ thống.
- **`No dbt_project.yml found at expected path ...\data-pipeline-project\dbt_project.yml`**: đang đứng ở thư mục gốc repo. `dbt_project.yml` nằm trong `bi_dbt\`; chạy `cd bi_dbt` rồi gõ lại lệnh dbt.
- **Cột khai báo trong yml nhưng không có trong file SQL** (ví dụ `cost` và `retail_price` ở `dim_products`): theo mình biết, dbt không báo lỗi. Luôn đối chiếu danh sách cột yml với file SQL.
- **Cảnh báo vàng `RuntimeWarning: "table_owner" does not match the name of any column`** khi `dbt docs generate`: cảnh báo của thư viện `agate`, catalog vẫn ghi xong, bỏ qua được (nguyên nhân chưa kiểm chứng).
- **Các dòng `404 File not found` (getIcon, favicon.ico) khi `dbt docs serve`**: lỗi biểu tượng của giao diện web, không ảnh hưởng nội dung.
- **`Ctrl+C` không dừng được `dbt docs serve`**: thử `Esc` rồi `Ctrl+C` lại, hoặc `Ctrl+Break`, hoặc đóng cửa sổ Anaconda Prompt (an toàn, chỉ phục vụ file tĩnh).
- **`AttributeError: Property maximum_byte_billed is unknown`**: gõ thiếu chữ `s`, tên đúng là `maximum_bytes_billed`. Lỗi nổ lúc tạo cấu hình, trước khi query được gửi nên không tốn tiền. Sửa trong Cell 1 rồi chạy lại Cell 1 trước, sau đó mới chạy lại cell dùng hàm.
- **`'name' is a required property` / `Custom key 'Name'` khi `dbt compile`**: khóa yml viết hoa chữ `N` (`- Name:`); YAML phân biệt hoa thường. Đọc tên khóa trong dòng cảnh báo rồi so với các khối đã chạy tốt. Sau khi sửa, `Found` đủ 15 data tests.
- **`AttributeError` với `job.total_bytes_process`**: thiếu `ed`, tên đúng là `total_bytes_processed`. Cell định nghĩa hàm vẫn chạy xanh vì chưa gọi hàm; lỗi nổ lúc gọi `check(sql)`. Sửa Cell 1 rồi chạy lại Cell 1 trước, sau đó mới chạy cell gọi hàm.
- **Tên measure Power BI gõ sai chính tả (`Goss` thay `Gross`)**: Power BI không báo lỗi. Sửa phần tên trước dấu `=` trong thanh công thức, biểu đồ tự cập nhật.
- **Kéo cột số vào biểu đồ rồi đổi sang Average** (implicit measure): ra số hợp lệ nhưng khác nghĩa (lợi nhuận trung bình mỗi dòng 30,56, không phải biên 51,8%); không có lỗi đỏ. Số đưa vào dashboard phải là explicit measure.
- **`The selection criterion 'dim_date' does not match any enabled nodes` dù `Found 8 models` (đã tăng từ 7)**: dbt thấy một file model mới nhưng không có model tên `dim_date`. Nguyên nhân chưa xác nhận (nghi tên file lệch một chút, ví dụ do bộ gõ tiếng Việt); sau khi chỉnh thì `dbt compile --select dim_date` tìm thấy. `dbt ls --resource-type model` hoặc `dir models\marts` để xem tên thật. Dòng vàng không dừng lệnh, chỉ in `Nothing to do`.
- **`Custom key 'data_test' found` (thiếu chữ `s`)**: đúng là `data_tests:`. dbt chỉ báo dòng vàng `CustomKeyInObjectDeprecation`, bỏ qua khóa lạ nên test bị mất âm thầm; dấu hiệu là số test: `17 data tests` thay vì `18`. Luôn so số `Found ... data tests` với số mong đợi.
- **Power BI: không thấy "Hide in report view"**: chuột phải cột → **Hide**; **View hidden** là công tắc hiện lại các cột đã ẩn, bật một lần cho cả mô hình. Chọn nhiều cột bằng Ctrl. Giao diện mới có nhóm Calendar options thay nút Mark as date table cũ.
- **Kéo `dim_date` sang `fct_net_sales` ra "One to many"**: không sai, chỉ là cách đọc theo bảng From. Kiểm tra bằng Manage relationships: phía một là dimension, Single, active.
- **`BadRequest: Unclosed identifier literal at [7:6]`** khi chạy SQL trong notebook: dòng `FROM` thiếu dấu backtick đóng quanh tên bảng (`[dòng:cột]` chỉ vị trí trong câu SQL, không phải trong cell). Lỗi dừng ở bước kiểm tra cú pháp nên không tốn tiền. Cùng cell còn có chữ `department` gõ thừa (`departmnent`); lỗi gõ tên cột chỉ lộ sau khi lỗi dấu backtick được sửa.
- **Power BI: Matrix chưa đổi sau khi chọn slicer**: thành phần cập nhật không cùng lúc, chụp ảnh quá sớm sẽ thấy số cũ. Chờ vài giây rồi mới đối chiếu (đã gặp ở Data Studio, giờ gặp ở Power BI).
- **`BadRequest: Syntax error: Unexpected keyword ORDER at [16:39]`** khi chạy SQL: thừa dấu phẩy giữa `PARTITION BY` và `ORDER BY` trong `OVER (...)` (`PARTITION BY y, ORDER BY mth`). Đúng là `OVER (PARTITION BY y ORDER BY mth)`. `[dòng:cột]` tính từ dòng đầu của câu SQL (dòng ngay sau `"""` là dòng 1); lỗi dừng ở bước dry run nên không tốn tiền.
- **Dùng tên hàm DAX trong SQL** (`DIVIDE` thay vì `SAFE_DIVIDE`): BigQuery không có `DIVIDE`; dễ lẫn khi vừa viết DAX. Sửa thành `SAFE_DIVIDE`.
- **Measure sửa dở, số không đổi**: thanh công thức vẫn hiện ✗ và ✓ nghĩa là chưa áp dụng; phải bấm ✓ hoặc Enter. Biến `VAR` khai báo mà `RETURN` không dùng thì không có tác dụng và không báo lỗi.
- **`TOTALYTD` ở tháng không có dữ liệu** vẫn hiện số cộng dồn đến cuối năm; **YoY −100%** vì BLANK coi như 0 trong phép trừ; **Total năm đang chạy so với cả năm trước**. Cả ba không có lỗi đỏ; kiểm bằng SQL cùng kỳ (Cell 3) và nhìn các tháng sau ngày dữ liệu cuối.
- **Slicer `year_number` còn năm 2027**: do `dim_date` phủ đến 2027, không phải lỗi. Lọc slicer bằng `Net Revenue` is not blank.
- **Measure sai nghĩa nhưng không báo lỗi** (`Avg Order Value` 61,00 thay vì 88,68): DAX chỉ kiểm cú pháp. Phát hiện bằng đối chiếu SQL độc lập cùng bản chụp, cùng điều kiện lọc; thẻ đổi khi bấm biểu đồ không chứng minh được gì vì measure đúng cũng đổi.
- **Thẻ `Data Through` đổi khi bấm biểu đồ đường**: `MAX(order_date)` tính trên tập dòng đã bị thu hẹp. Sửa bằng `CALCULATE(..., REMOVEFILTERS(dim_date), REMOVEFILTERS(dim_products))` và tắt tương tác lên thẻ (Format, Edit interactions).
- **Biểu đồ Top N dễ bị đọc là toàn bộ**: 10 category chỉ khoảng 68,3% tổng; danh sách đổi khi chọn department. Ghi "Top 10" ở tiêu đề.
- **Vòng `for` không chạy khi `df` rỗng, và đó không phải null**: `len(df)` bằng 0 là tập rỗng (không có dòng nào khớp), khác một ô có giá trị null. Cell vẫn xanh vì SQL đúng và lặp qua danh sách rỗng là hợp lệ. Cell 5b và 5c rỗng nghĩa là Power BI không thấy trong `JOBS`, không phải lỗi code.
- **Nạp CSV toàn STRING bỏ `skip_leading_rows=1`**: load job không báo lỗi, dòng tiêu đề thành một dòng dữ liệu (72 thay vì 71). Chạy lại bằng `WRITE_APPEND` thì trùng dòng, cũng không báo lỗi. Luôn so số dòng bảng với số dòng đếm từ file CSV.
- **`AttributeError: module 'google.cloud.bigquery' has no attribute 'schemaField'`**: gõ chữ `s` thường, tên đúng là `SchemaField`. Lỗi nổ trước khi load job được gửi nên không tốn gì và bảng chưa được nạp. Khối `try/except` nuốt lỗi nên cell vẫn xanh; phải đọc output tìm chữ `LỖI`. Sửa Cell 2 rồi chạy lại Cell 2 trước, sau đó chạy lại Cell 3.
- **`FileNotFoundError` bị `except` nuốt khi file nguồn thiếu**: bảng đó không được nạp, nhưng bảng cũ từ lần trước vẫn nằm trên BigQuery, không có dấu hiệu nào cho biết là bản cũ. Đọc dòng `Bảng có vấn đề: [...]` ở cuối Cell 3.

- **Luật `.gitignore` không có dấu `/` ở đầu chặn nhầm thư mục cùng tên ở sâu bên trong**: `olist/` (dòng 226) chặn cả `olist_dbt/models/staging/olist/`; ba file `.sql`/`.yml` chính không hiện trong `git status` và không có lỗi nào báo. Kiểm bằng `git check-ignore -v <đường dẫn>` (in ra dòng luật đang chặn); sửa thành `/olist/` (chỉ chặn ở gốc repo) rồi kiểm lại.
- **`git grep` trong Anaconda Prompt báo `'AIza' is not recognized`**: Anaconda Prompt là `cmd`, nháy đơn không hoạt động và `|` bị hiểu là pipe. Dùng nháy kép: `git grep --cached -n -i -E "@gmail|AIza|private_key|api_key"`. `--cached` chỉ quét file đã `git add`; sau khi đã commit thì dùng `git grep ... HEAD`.

## 10. Quyết định đã chốt
- Dùng VS Code thay vì Jupyter riêng (sẽ cần viết nhiều file `.sql`/`.yml` cho dbt).
- Chỉ học một cloud warehouse (BigQuery) cho đến khi xong lộ trình.
- Dùng một tài khoản GitHub duy nhất (`khoatranuk-sys`).
- Lưu mọi câu SQL tạo bảng vào thư mục SQL trong repo (hiện là `SQL/Day 2/`, bảng sandbox có thể hết hạn).
- Không đẩy file dữ liệu lên GitHub: `data/` đã nằm trong `.gitignore` (làm xong Ngày 3).
- Ngày 2: fact và dimension nối bằng khóa tự nhiên (`user_id`, `product_id`, `date_key`), chưa dùng dbt snapshot (SCD Type 2 trên dữ liệu thật) là việc tùy chọn, dùng ở Tuần 9-10 nếu dữ liệu có thay đổi theo thời gian.
- Quy ước đặt tên bảng trong dataset `dwh`: `dim_*` và `fact_*`, số nhiều (`dim_users`, `dim_products`, `fact_order_items`).
- Quy ước SCD Type 2 trong ghi chú: một ngày thuộc dòng nào nếu `valid_from <= ngày < valid_to`, dòng hiện tại có `valid_to = NULL` (khi lọc phải xử lý NULL riêng).
- Doanh thu thực tế loại đơn `Cancelled` và `Returned`.
- Ngày 3: mọi lệnh gọi API trong pipeline dùng hàm `get_json` (có `timeout`, retry cho 5xx/429/mất mạng, không retry 4xx). Dữ liệu trung gian giữa các bước lưu bằng Parquet, CSV chỉ dùng khi cần giao file cho người xem. Thêm cột `ingested_at` (thời điểm lấy dữ liệu) vào bảng nạp từ API.
- Học Python ở mức đọc hiểu ý tưởng, không học thuộc cú pháp; giữ notebook trong repo làm sổ tay mẫu để dùng lại.
- Ngày 4: bảng dữ liệu thô từ API đặt trong dataset `raw`; bảng nhỏ nạp bằng `WRITE_TRUNCATE` để chạy lại không bị trùng. Luôn khai báo schema rõ khi nạp, và kiểm tra số dòng sau khi nạp.
- Mọi bí mật (API key) để trong `.env`, chỉ commit `.env.example`; không `print` khóa; trước khi commit notebook tìm thử một đoạn khóa bằng Ctrl+Shift+F. Nếu khóa thật bị lộ lên GitHub thì thu hồi và tạo khóa mới ngay.
- Commit bằng `git add` từng file (không dùng `git add .`) rồi `git status` kiểm tra trước khi commit.
- Cài thư viện cho kernel `bi` bằng `%pip install` trong notebook.
- Ngày 5: pipeline luôn theo thứ tự lấy, làm sạch, kiểm tra, nạp; kiểm tra thất bại thì dừng, không nạp bừa. Ghi log ra màn hình và file `logs/` (không commit); script trả mã thoát 0 hoặc 1 để công cụ lập lịch biết kết quả.
- Pipeline chạy tự động thì dựa vào cầu chì và cổng kiểm tra tự động (`maximum_bytes_billed`, `validate_weather`), không dựa vào mắt người.
- Gom các hàm đã thử trong notebook vào một file `.py` có hàm `main()` khi muốn chạy bằng một lệnh.
- Repo cá nhân: commit thẳng lên `main`, chọn từng file bằng `git add <file>`, dùng nhánh và Pull Request khi muốn thử nghiệm hoặc làm nhóm.
- Ngày 6: luôn chốt grain của bảng fact trước khi thiết kế; chọn SCD 1 khi không cần giữ lịch sử, SCD 2 khi báo cáo quá khứ phải giữ nguyên (chấp nhận bảng to hơn, nối phức tạp hơn).
- Không dùng `SELECT *` trên bảng lớn; luôn liệt kê cột cần dùng.
- Tuần 2, Ngày 4: doanh thu thực tế **chỉ tính đơn `Complete`** (loại `Shipped`, `Processing`, `Cancelled`, `Returned`); viết điều kiện dạng `status = 'Complete'` để trạng thái mới không lọt vào doanh thu một cách âm thầm. Quy tắc này nằm trong `lab.v_net_sales` và `lab.mv_net_sales_daily`.
- Dashboard đọc từ materialized view `lab.mv_net_sales_daily` (nhỏ, đã tính sẵn), không đọc thẳng từ bảng gốc.
- Số trên dashboard luôn đối chiếu với một câu SQL độc lập trước khi tin; tỷ lệ tính bằng tổng chia tổng.
- Chưa bấm Share dashboard cho đến khi hiểu phần chia sẻ gắn với IAM.
- Biểu đồ theo thời gian dùng Year Month, ghi chú khi tháng cuối chưa trọn.
- Tuần 3, Ngày 2: dùng dbt Core cài bằng `pip` trong môi trường `bi`; kết nối `method: oauth`, không dùng service account hay file khóa (repo công khai). `profiles.yml` ở ngoài repo, không commit. Mọi query dbt có `maximum_bytes_billed: 1000000000`. dbt ghi vào dataset `dbt_dev` (US), tách khỏi `lab`, `dwh`, `raw`.
- Trước khi commit thư mục mới: `git status -uall` để xem từng file bên trong, bảo đảm không có `logs/`, `target/` hay file bí mật.
- Tuần 3, Ngày 3: staging model chỉ đổi tên, chọn cột, ép kiểu (không có quy tắc nghiệp vụ); staging dùng `view`. Quy tắc doanh thu chỉ tính `Complete` nằm ở tầng mart. Luôn `dbt run --select <model>`, không chạy `dbt run` trần khi còn `models/example/`.
- Số dòng của view dbt thay đổi theo bảng nguồn công khai; bảng `lab` và `dwh` là bản chụp cố định. Khi đối chiếu, so sánh trong cùng khoảng ngày rồi mới kết luận.
- Tuần 3, Ngày 4: mart đọc từ staging bằng `ref` (staging đọc bảng public), kiểu `table`: số liệu đứng yên cho đến lần `dbt run` kế tiếp, nên Power BI đọc bảng này; chạy lại một model `table` là ghi đè bản chụp cũ, không giữ lịch sử. Không đối chiếu mart với `lab.fact_items_plain` (nguồn đã lệch); đối chiếu mart với staging cùng lúc. Mart dùng `left join` và kiểm tra `cost IS NULL` + so số dòng với staging, không dùng `join` thường. Tên mart trong dbt: `fct_*` và `dim_*` (khác `fact_*` ở dataset `dwh`).
- Tuần 3, Ngày 5: Power BI đọc bảng mart `dbt_dev` bằng Import mode (không dùng DirectQuery), không nạp view `stg_*`. Quan hệ `fct_net_sales.product_id` → `dim_products.product_id`, Many to one, Single. Đối chiếu số trong Power BI với SQL chạy trên cùng bảng mart. `.pbix` để ngoài repo cho đến khi quyết định ở Tuần 5. Làm mới số liệu theo thứ tự: `dbt run` rồi Refresh Power BI.
- Lộ trình theo `lo_trinh_BI_checklist.xlsx` (BI-only, 69 việc cho Tuần 1-10); phần AI Logistics nằm ở file riêng (`lo_trinh_AI_Logistics.xlsx`, `CONTEXT_AI_Logistics.md`). Ứng tuyển bắt đầu sau Tuần 10. Project 1 dùng thelook (dữ liệu mô phỏng, để học công cụ); Project 2 dùng dữ liệu thật (đề xuất Olist, giấy phép chưa xác nhận); Tuần 9-10 làm project mới trên bộ dữ liệu khác.
- Tuần 4, Ngày 1: test của dbt khai báo trong file yml cạnh model (`models/marts/_marts__models.yml`). Mỗi mart có ít nhất `unique` + `not_null` trên khóa và `relationships` từ fact sang dim. Luôn `GROUP BY` xem giá trị thật trước khi viết `accepted_values`. Sau mỗi `dbt test`, đọc dòng WARNING vàng và so `TOTAL` với số test mong đợi.
- Tuần 4, Ngày 2: mỗi mart và source có `description` ngay trong yml (mô tả bảng nói rõ grain và quy tắc nghiệp vụ). Chỉ chạy `dbt docs generate` khi mô tả hoặc cấu trúc đổi (tốn khoảng 100 MB mỗi lần); xem lại tài liệu thì dùng `dbt docs serve` (miễn phí). Mọi lệnh dbt chạy trong `bi_dbt`. Câu hỏi lệch mục đích của ngày ghi vào mục 11 và làm sau khi xong phần chính.
- Tuần 4, Ngày 3: chỉ dùng `incremental` khi nguồn chỉ thêm dòng hoặc có cột `updated_at` đáng tin; nguồn sửa dòng cũ mà không biết dòng nào thì giữ `table`. Model incremental luôn đi kèm `unique_key` và đối chiếu với nguồn (thiếu, thừa) trước khi tin; không coi `dbt test` là đối chiếu nguồn. Mart incremental mới đặt tên `fct_*_inc`, không thay `fct_net_sales` mà Power BI đang đọc.
- Tuần 4, Ngày 4: số nào đưa vào dashboard hoặc đối chiếu phải là explicit measure (đặt tên đúng, định dạng một lần), không dùng implicit measure. Tỷ lệ luôn là `DIVIDE([tử], [mẫu])` của hai tổng, không lưu tỷ lệ từng dòng thành cột. Measure đặt trong bảng `fct_net_sales`; đối chiếu với SQL trên cùng bảng mart và cùng bản chụp (không Refresh giữa chừng).
- Tuần 4, Ngày 5: `dim_date` làm bằng dbt (mart `table`, không đọc bảng nguồn), phủ 2019-2027, có `unique` + `not_null` trên `date_day` và `relationships` từ `fct_net_sales.order_date`. Mọi trục thời gian trong Power BI dùng `dim_date`, tắt Auto date/time. Ẩn cột khóa và cột thô trong fact, giữ lại measure; không đưa implicit measure vào dashboard. Lọc đi một chiều (Single) từ dimension sang fact; không dùng quan hệ hai chiều. Khi thêm bảng vào Power BI chỉ nạp bảng mới, không Refresh `fct_net_sales` giữa lúc đang đối chiếu số.
- Tuần 4: việc CV và LinkedIn dời về Tuần 8 (Portfolio), để các tuần kỹ thuật không bị cắt ngang. Khi tới Tuần 8 làm gộp, dùng các số đo từ Project 1 và 2.
- Tuần 5, Ngày 1: filter ghi đè khi dùng `CALCULATE` là có chủ ý; measure mẫu `Net Revenue Men`, `Net Revenue 2025` chỉ để học, không đưa vào dashboard thật. Mẫu số "tổng" dùng `REMOVEFILTERS` trên đúng bảng cần gỡ. Số cũ (45.529 dòng) không còn: `dbt run` đã ghi đè `fct_net_sales` bằng bản chụp mới (45.285 dòng). Muốn so sánh số giữa các ngày thì lưu bản chụp có đánh ngày hoặc dùng nguồn không đổi.
- Tuần 5, Ngày 2: so sánh cùng kỳ năm trước phải cắt `ly` ở cùng ngày-tháng với ngày dữ liệu cuối (dùng `LastData` tính bằng `REMOVEFILTERS(dim_date)`), không so năm đang chạy với cả năm trước. Measure hiển thị theo thời gian trả BLANK khi chưa có dữ liệu (`IF(ISBLANK(...))`). Giữ `dim_date` phủ đến 2027 (không rút ngắn); lọc slicer năm bằng `Net Revenue` is not blank. Không cần Mark as date table cho mô hình hiện tại (đã đo). Trước khi giao dashboard thật: kiểm `MAX(order_date)`, số ngày có dữ liệu của tháng cuối, và đối chiếu một câu SQL cùng kỳ với dòng Total.
- Tuần 5, Ngày 3: mọi số trên thẻ KPI phải khớp một câu SQL độc lập (cùng bản chụp, cùng điều kiện lọc) trước khi tin. Thẻ "ngày dữ liệu cuối" dùng `REMOVEFILTERS`. Biểu đồ chọn tháng không được lọc lên thẻ KPI (Edit interactions). Biểu đồ Top N ghi rõ "Top 10" ở tiêu đề. `.pbix` vẫn để ngoài repo (`D:\BI\powerbi\`).
- Tuần 5, Ngày 4: mô hình Power BI chỉ giữ cột thật sự dùng; bỏ cột ở Power Query (không chỉ ẩn); cột vẫn nằm trong BigQuery. Mọi thay đổi mô hình phải đối chiếu lại thẻ KPI với một câu SQL cùng bản chụp. Số đo thời gian (ms) chỉ kết luận được khi đo nhiều lượt và điều kiện giống nhau; không đo lần đơn lẻ.
- Tuần 5, Ngày 5: Project 1 xong khi đủ 6 tiêu chí: `dbt test` đạt toàn bộ test của 4 mart (mong đợi PASS=14); mọi thẻ KPI khớp một câu SQL độc lập; star schema (`fct_net_sales` giữa, `dim_products` và `dim_date`, Single); cầu chì chi phí ghi trong README; README đủ (mục tiêu, nguồn, kiến trúc, cách chạy lại, hạn chế); repo không có bí mật, `.pbix`, `data/`.
- Tuần 5, Ngày 5: công cụ BI chính là Power BI, Looker Studio là công cụ phụ; ngách là logistics và e-commerce (vận hành giao hàng); Airflow và Docker tiếp tục hoãn (Docker 0/27 tin, Airflow chỉ ở tin kỹ sư).
- Tuần 5, Ngày 5: Project 2 thêm hai tiêu chí xong ngoài 6 tiêu chí: (7) pipeline chạy theo lịch không cần can thiệp, mỗi lần chạy có log từng bước (Extract, Transform, Load, `dbt run`, `dbt test`), mã thoát 0 hoặc 1, một chỗ duy nhất để xem kết quả; lỗi không được lộ ra âm thầm (kiểm số dòng nạp, `validate`, dòng vàng của dbt); (8) README ghi nguồn, giấy phép và nêu rõ không dùng cho khách trả tiền.
- Tuần 5, Ngày 5: Project 2 là một repo mới hoàn toàn tên `olist-bi-project` (cùng tài khoản `khoatranuk-sys`, không dùng chung với `data-pipeline-project`). Dữ liệu Olist gốc giữ ở một chỗ (`D:\BI\projects\ai-logistics\data\olist`), không chép vào repo; script đọc đường dẫn từ `.env` (`OLIST_DIR`). Nạp lên BigQuery bằng load job vào dataset riêng (`olist_raw`, US); dbt dùng dataset riêng, tách khỏi `dbt_dev`. `.gitignore` tạo trước khi có file dữ liệu đầu tiên. Repo tạo ở Tuần 6, Ngày 1 (chưa tạo).
- Tuần 5, Ngày 5: nếu dữ liệu là bản đóng băng thì "cập nhật tự động" được mô phỏng bằng cách nạp từng khối thời gian, mỗi lần chạy thêm một khối; README ghi rõ đây là mô phỏng. Quota `Query usage per day` phải đặt trước khi bật lịch chạy (chờ nâng cấp trả phí, hạn quyết định 06/01/2027).
- Tuần 5, Ngày 6: README `data-pipeline-project` giữ lẫn tiếng Việt (phần thời tiết) và tiếng Anh (Project 1) đến Tuần 8 (Portfolio). Ba file thử `Ghi_chu.txt`, `test_bq.ipynb`, `viewtable.ipynb` vẫn để trong repo. Quét bí mật bằng `git grep` (dấu nháy đơn trong PowerShell) phải xong **trước** khi push; kiểm file lạ bằng `git ls-files | Select-String`. Dữ liệu Olist gốc ở `D:\BI\projects\ai-logistics\data\olist`; `OLIST_DIR` trong `.env` của repo mới trỏ tới đường dẫn này.
- Tuần 6, Ngày 1: Project 2 dùng lại project GCP `bq-learning-510104` (không tạo project mới vì billing, budget, tín dụng dùng thử đang gắn ở đây), tách bằng dataset riêng. Repo giữ tên `olist-bi-project`. `.gitignore` và kiểm tra `check-ignore -v` phải xong trước khi có file dữ liệu đầu tiên; quét bí mật trước khi push.
- Tuần 6, Ngày 2 (đề xuất, chốt ở Ngày 3): mô phỏng cập nhật tự động bằng cách chia theo `orders.order_purchase_timestamp` theo tháng (`items`, `payments`, `reviews` đi theo `order_id`); khi nối `products` với `translation` dùng `left join` (623 sản phẩm không có tên tiếng Anh); `geolocation` gom về một dòng một zip trước khi nối; luôn so số dòng trước và sau khi nối.
- Tuần 6, Ngày 3: `olist_raw` nạp bằng load job, mọi cột STRING (khai báo schema rõ từ dòng tiêu đề), `skip_leading_rows=1`, `WRITE_TRUNCATE` (chạy lại không trùng), `allow_quoted_newlines=True`. Ép kiểu ở dbt staging bằng `SAFE_CAST`, mã zip giữ STRING. Mỗi bảng nạp xong phải so số dòng đích (`num_rows` hoặc `COUNT(*)`) với số dòng đếm từ file CSV. Sửa dòng cũ "Repo tạo ở Tuần 6, Ngày 1 (chưa tạo)" thành "đã tạo".
- Tuần 6, Ngày 4: tên bảng raw của Project 2 bỏ `olist_` và `_dataset`. Mỗi lần nạp bảng, đối chiếu ít nhất 4 số dòng gồm một nguồn đứng ngoài BigQuery (đếm từ file CSV); `n_job` và `n_tbl` cùng phía BigQuery nên không thay được nguồn ngoài. Mã zip giữ nguyên STRING ở raw. Ô comment trống ở `order_reviews` là NULL, không phải chuỗi rỗng. Khi nối `products` với `translation` luôn dùng `left join` rồi xử lý 623 dòng NULL ở staging, và so số dòng trước và sau khi nối.
- Tuần 6, Ngày 5: dbt của Project 2 nằm trong `olist_dbt/`, ghi vào dataset `olist_dbt_dev` (US), tách khỏi `dbt_dev`; mọi query dbt có `maximum_bytes_billed: 1000000000`. Staging đọc `olist_raw` bằng `source('olist', ...)`, chỉ đổi tên và ép kiểu bằng `SAFE_CAST` (không có quy tắc nghiệp vụ). Mỗi cột ép kiểu mới phải so NULL trước và sau ép trên bảng raw. Luật `.gitignore` của thư mục dữ liệu viết dạng `/olist/` (neo ở gốc repo). Thứ tự trước khi đẩy: `git add` từng file, `git status`, quét bí mật, rồi mới commit và push.

## 11. Câu hỏi còn mở
- Công cụ BI nào xuất hiện nhiều nhất trong 10-20 tin tuyển dụng quanh mình (Power BI, Tableau hay Looker Studio)?
- Ngách nghiệp vụ cho Project 2 và freelance là gì?
- Materialized view có tự cập nhật khi bảng gốc đổi không, và phí làm mới sau khi bật billing là bao nhiêu (chưa kiểm chứng).
- BigQuery có tự dùng MV khi mình hỏi trên bảng gốc không (Cell 9 Tuần 2 chỉ quét 0,04 MB, nghi là có, chưa kiểm chứng).
- Vì sao các query đọc `INFORMATION_SCHEMA.JOBS` bị tính billed 20 MB thay vì 10 MB (chưa hiểu).
- Chia sẻ dashboard Data Studio ra ngoài cần quyền gì ở BigQuery (liên quan IAM), làm sau.
- Nếu nhiều tin tuyển dụng yêu cầu Airflow/Docker thì có học sớm hơn không (hiện đang hoãn, Tuần 9-10 là Project thành thạo)?
- Vì sao view dbt và `lab.fact_items_plain` lệch số dòng (181.466 và 180.771; chênh đổi dấu qua từng năm)? Giả thuyết là bảng nguồn công khai được cập nhật, chưa chứng minh (cần xem lại SQL tạo bảng lab ở Tuần 1).
- Mart ở Tuần 3 Ngày 4 đọc thẳng bảng public hay đọc từ một bản chụp của mình (ổn định, đối chiếu được)?
- (thêm câu hỏi khác tại đây)
- `fct_net_sales` có 45.529 dòng `Complete`, còn bản `lab` là 45.282 (chênh 247). Vẫn chưa chứng minh được là do nguồn public đổi.
- `max(order_date)` trong `fct_net_sales_inc` tụt từ 2026-10-18 xuống 2026-10-16 sau `MERGE` (đoán là có dòng ghi đè với `order_date` mới), và trong 454 dòng có bao nhiêu dòng thật sự khác? Chưa kiểm chứng.
- `MERGE` processed nhiều hơn `CREATE TABLE` (13,3 so với 10,5 MiB): có phải vì đọc thêm bảng đích? Staging view có bị quét hết dù có lọc ngày không? Chưa kiểm chứng.
- Bảng `order_items` có `shipped_at`, `delivered_at`, `returned_at` để làm cột mốc lọc incremental không (staging hiện không chọn các cột đó)? Chưa kiểm tra.
- Làm sao xóa khỏi bảng incremental các dòng không còn khớp điều kiện ở nguồn (đơn Complete sang Returned)? Chưa thử.
- Thí nghiệm xóa 2 ngày cuối của `fct_net_sales_inc` rồi `dbt run` để thấy `MERGE` thêm dòng mới: chưa làm.
- Truy vấn trên view cũng billed 10 MB (một lần đo ngày 09/10). Câu có hai bảng tham chiếu billed 20 MB (đo lại ngày 11/10: processed 0,57 MB, billed 20 MB), ủng hộ giả thuyết "mức tối thiểu 10 MB tính theo từng bảng"; mới hai lần đo.
- Mỗi lần Refresh trong Power BI đọc bao nhiêu byte, và qua job thường hay Storage Read API (chưa đo)?
- Xem lịch sử job bằng Python không dùng SQL (`client.list_jobs`): chưa thử.
- Bảng hệ thống thứ 5 mà `dbt docs generate` đọc (Cell 5 chỉ nhận ra `MATERIALIZED_VIEWS`, `TABLE_OPTIONS`, `COLUMNS`, `COLUMN_FIELD_PATHS`) là bảng nào? Cell 6 (`UNNEST(referenced_tables)`) để xem; chưa kiểm chứng.
- Vì sao query catalog của `docs generate` không lấy từ cache (giả thuyết: query đọc `INFORMATION_SCHEMA` không được cache)? Chưa kiểm chứng.
- Lineage mặc định không vẽ node test (giả thuyết, chưa kiểm chứng trên dbt 1.12.5).
- `persist_docs` có đẩy mô tả yml sang cột Description của BigQuery không, và hoạt động thế nào với bảng `table`? Chưa thử.
- `Orders` cộng đúng theo department năm 2026 (5.506 + 5.577 = 11.083); chưa kiểm các năm khác.
- `YoY %` khi slicer năm chọn nhiều năm (slicer đang kiểu Between) có còn đúng không? Chưa thử.
- Bảng `dim_products` có đúng 26 category không (bạn nêu, chưa kiểm bằng SQL)?
- Vì sao `Gross Margin %` ở các dòng category lệch nhau ít (37% đến 62%) trong khi doanh thu mỗi dòng rất khác nhau? Chưa phân tích, để dành cho bước thiết kế dashboard Tuần 5.
- Có cần Mark as date table cho time intelligence (YTD, so cùng kỳ) ở Tuần 5 không, và dùng cách đánh dấu nào ở phiên bản Power BI này (hộp thoại ghi "not recommended")?
- Có thêm `dim_users` (từ source `users`) vào star schema không, hay để Tuần 5?
- Vì sao lần `dbt run --select dim_date` đầu không tìm thấy model dù đã `Found 8 models` (nghi tên file, chưa xác nhận)?
- Chi phí thật của `dbt test --select dim_date fct_net_sales` (7 test) chưa đo bằng `INFORMATION_SCHEMA.JOBS`.
- Vì sao doanh thu năm 2025 đổi (624.117,64 sang 615.360,21) khi năm đã qua? Giả thuyết: nguồn mô phỏng đổi trạng thái đơn cũ. Chưa kiểm tra id (đã chọn bỏ qua, không làm).
- Mỗi lần Refresh Power BI đọc bao nhiêu byte? Không thấy lần Close & Apply ngày 22/10 trong `INFORMATION_SCHEMA.JOBS` (24 giờ và 60 phút); khả năng là đường đọc khác không tạo job, chưa kiểm chứng. Kiểm Billing Reports ngày 23/10.
- Việc bỏ cột có làm bớt byte đọc từ BigQuery khi nạp không (cần thấy câu SQL của Power BI)? Chưa biết.
- Chỉ ẩn cột thì `.pbix` có đổi dung lượng không? Chưa làm thí nghiệm.
- Close & Apply có nạp lại cả hai bảng hay chỉ bảng đã sửa? Chưa kiểm chứng.
- Vì sao Cell 5c in `Sẽ quét: None MB` và `billed 0.0 MB` trong khi Cell 5 và 5b in 0,01 MB và 20 MB? Chưa hiểu.
- `EDATE(LastData, -12)` với ngày 29/02 xử lý thế nào, và `DATEADD(LastData, -1, YEAR)` có cho cùng kết quả không? Chưa thử.
- Lọc slicer bằng measure (`Net Revenue` is not blank) có làm chậm hoặc đổi theo bộ lọc khác không? Chưa kiểm chứng.
- Olist là bản chụp 2016-09-04 đến 2018-10-17 (đã xác nhận), không tự cập nhật. Còn mở: cách chia items, payments, reviews theo khối tháng cho khớp orders khi mô phỏng cập nhật.
- `D:\BI\Dataset` (5 file nhỏ) là dữ liệu gì, từ đâu? Chưa mở xem; không dùng cho Project 2.
- Chạy pipeline theo lịch bằng gì: Windows Task Scheduler (đề xuất, hợp với `oauth`, không file khóa), BigQuery scheduled query (chỉ chạy SQL), hay GitHub Actions (chưa rõ cách xác thực không dùng khóa)? Quyết định ở Tuần 6.
- Giấy phép NC có ảnh hưởng thế nào khi dùng dữ liệu trong portfolio để xin việc (vùng xám, chưa phải luật sư)?
- Nhiều tin tuyển dụng ghi ETL: họ muốn viết pipeline hay chỉ dùng dữ liệu đã qua ETL? Chưa đọc trọn các JD đó.
- review_id trùng 814 dòng (cặp review_id + order_id thì duy nhất): vì sao lặp?
- customer_unique_id có lặp qua nhiều customer_id không?
- 13 sản phẩm mồ côi thuộc mấy category, và có tên nào cần đoán nghĩa không?
- geolocation: gom về một dòng một zip bằng cách nào (trung bình, lấy dòng đầu)? Quyết ở staging.
- Ô trống ở các cột khác của `order_reviews` (và các bảng khác) cũng thành NULL hay chuỗi rỗng? Mới kiểm `review_comment_message`.
- Có zip nào bắt đầu bằng `'0'` trong raw không (mới suy ra từ độ dài 5)? Chưa đếm trực tiếp.
- Bỏ `job.result()` thì `output_rows` có thật sự là `None` không? Chưa thử.
- `customers`, `sellers`, `geolocation` có zip nào không khớp giữa ba bảng không? Chưa kiểm; làm ở staging.
- order_status đã xác nhận có 8 giá trị (xem mục 7).
- NULL ở `order_delivered_carrier_date` (1.783) và `order_delivered_customer_date` (2.965) có khớp với các trạng thái chưa giao (`canceled`, `unavailable`, `shipped`...) không? Chưa kiểm bằng SQL.


## 12. Cách mình muốn được trả lời
- Tiếng Việt, từng bước rõ ràng, lệnh gõ nguyên văn (mình dùng Windows).
- Nói rõ nơi chạy lệnh (Anaconda Prompt, VS Code, hay BigQuery web).
- Mình thường gửi ảnh chụp màn hình khi vướng, hãy đọc kỹ ảnh trước khi kết luận.
- Cảnh báo trước nếu một bước có thể tốn tiền hoặc khó hoàn tác.
- Khi mình đã hoàn thành một ngày, chỉ cần nội dung ngày kế tiếp, không lặp lại phần cũ.
- Nói rõ điều gì chưa chắc chắn thay vì đoán.
- Với phần code mới: giải thích mỗi bước để làm gì và dịch sang SQL khi có thể; nói rõ phần nào cần hiểu, phần nào không cần thuộc. Chia nhỏ từng cell, mỗi cell kèm kết quả mong đợi.
- Khi giải thích code: gửi nguyên script đúng như sẽ chạy, giải thích bằng comment (`#`) ngay trong code, không cắt script thành từng đoạn rời. Sau script ghi kết quả mong đợi, phần cần hiểu và phần không cần thuộc.
- Khi đưa cell notebook: ghi số cell trong code (`# Cell 3`).
- Đầu mỗi ngày mới: nói rõ mục đích của ngày đó.
- Cuối mỗi ngày: ôn code Python bằng 5-6 dòng quan trọng nhất của ngày. Hỏi từng câu một (mình trả lời bằng lời, rồi mới nhận xét, rồi mới sang câu sau), ghi mục đích của từng câu; trộn lại vài dòng cũ (nhất là dòng trả lời sai) vào ngày sau; không thêm phần dịch SQL sang pandas.
- Sau mỗi ngày học, soạn sẵn nội dung cập nhật `CONTEXT.md` và `Notes.md` cho mình (không chỉ liệt kê việc cần làm).

- Đầu mỗi ngày mới, ngay sau phần mục đích của ngày: đưa bản tổng quan từ đầu đến cuối gồm **cả hai**: (1) bảng, và (2) **sơ đồ luồng dạng hình** (vẽ trong chat, theo hàng dọc, mỗi hàng gồm: chạy ở đâu, bước làm gì, kết quả hiện ra). Bản chữ hoặc ASCII bị vỡ dòng trên màn hình của mình nên không dùng thay cho hình. Mỗi bước theo thứ tự gồm: bước đó làm gì, chạy ở đâu (VS Code, Anaconda Prompt, BigQuery web, Power BI), và kết quả hiện ra là gì (output, file, bảng được tạo). Sau đó mới vào hướng dẫn chi tiết từng bước. Áp dụng từ Tuần 5 Ngày 1.
- Ôn cuối ngày: **không hỏi lại** những dòng code và khái niệm mình đã trả lời đúng trên khoảng 70% số lần; dành chỗ cho câu mới. Danh sách đã nắm chắc (mình quyết định): `client.query()` gửi job và không chờ; `use_query_cache=False` chỉ bỏ qua cache, không xóa gì; `df = job.result().to_dataframe()` chờ xong rồi đưa kết quả vào `df`, byte lấy từ `job` sau `result()`; `maximum_bytes_billed` nhân `1024 * 1024` đổi MB sang byte; `REMOVEFILTERS(bảng)` chỉ gỡ filter của bảng đó. Chưa chắc, vẫn hỏi lại: `CALCULATE` ghi đè filter cùng cột còn cột khác giữ nguyên; test dbt kiểm cấu trúc, không đối chiếu giá trị với nguồn.
Danh sách đã nắm chắc (mình quyết định): `client.query()` gửi job và không chờ; `use_query_cache=False` chỉ bỏ qua cache, không xóa gì; `df = job.result().to_dataframe()` chờ xong rồi đưa kết quả vào `df`, byte lấy từ `job` sau `result()`; `maximum_bytes_billed` nhân `1024 * 1024` đổi MB sang byte; `REMOVEFILTERS(bảng)` chỉ gỡ filter của bảng đó; `dry_run=True` chỉ kiểm tra và ước lượng, không cần `job.result()`. Chưa chắc, vẫn hỏi lại: `CALCULATE` ghi đè filter cùng cột còn cột khác giữ nguyên; test dbt kiểm cấu trúc, không đối chiếu giá trị với nguồn và không chạm tầng DAX; `LastData` luôn là ngày cuối của cả bảng, không đổi theo slicer; `def` chỉ định nghĩa hàm, `max_mb=100` là tham số mặc định, thiếu `return` thì `None`.

- “Chưa chắc, vẫn hỏi lại” (cập nhật Tuần 5 Ngày 6): `for` với `df` rỗng chạy 0 lần (không phải 1 lần); `def` chỉ định nghĩa, biến trong hàm mất khi hàm kết thúc, `return` đưa ra ngoài, thiếu `return` thì `None`; chữ `r` ngoài `"""` là Python, chữ `r` trong `'...'` là BigQuery; `relationships` tìm khóa mồ côi của fact (không phải NULL); `CALCULATE` ghi đè filter cùng cột, filter cột khác vẫn đi qua (đúng hôm nay, hỏi thêm một lần). Đã nắm: ETL biến đổi trước khi nạp, ELT nạp rồi biến đổi trong warehouse.
-“Chưa chắc, vẫn hỏi lại”: thêm cuối đoạn: “isin trả dãy True/False dài bằng bảng con; NULL khác mồ côi (610 NULL trong products, 13 mồ côi); nối sang bảng nhiều dòng cho một khóa thì nhân dòng; khi missing_cols rỗng code vẫn chạy tiếp Bước 3.”
- “Chưa chắc, vẫn hỏi lại” (Tuần 6 Ngày 3): `job.result()` chờ rồi mới đọc `output_rows`, không gán vào `job`; NULL khác mồ côi; `len(df)` khác số dòng của bảng; `WRITE_APPEND` chạy hai lần ra gấp đôi.

- "Chưa chắc, vẫn hỏi lại" (Tuần 6 Ngày 4): `len(df)` là số dòng của kết quả SQL, không phải số dòng của bảng (`df["so_dong"][0]`); `n_tbl` là `num_rows` của bảng BigQuery, không phải của pandas; `n_job` và `n_tbl` cùng phía BigQuery nên cần nguồn ngoài; `join` thường làm mất sản phẩm, `left join` giữ lại với tên NULL (623 = 610 NULL + 13 mồ côi); `print(len(TABLES))` là số bảng dự định; `except` nuốt lỗi và để lại bảng cũ.

- "Chưa chắc, vẫn hỏi lại" (Tuần 6 Ngày 5): `len(df)` là số dòng kết quả SQL, không phải số dòng bảng; ví dụ cho "test không bắt được" phải gắn với cột thật sự được test; `.gitignore` không có dấu `/` đầu khớp ở mọi cấp. Đã nắm: `check` là dry run, `stats` chạy thật; `processed` 9,86 MB nhưng `billed` 10,0 MB vì mức tối thiểu; hai số NULL bằng nhau nghĩa là `SAFE_CAST` không làm hỏng ô nào.