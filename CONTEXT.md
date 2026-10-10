# Ngữ cảnh học tập (dán file này vào đầu mỗi cuộc trò chuyện mới)

> Cập nhật lần cuối: 10/10/2026. Cuối mỗi ngày học, sửa mục "Đã hoàn thành", "Đang làm" và "Lỗi đã gặp" rồi commit.
> Repo này công khai: không ghi mật khẩu, API key, token, email cá nhân hay dữ liệu khách hàng thật.

## 1. Mục tiêu
- **BI là chính**, data engineering (DE) là phụ.
- Cần biết cloud data platform và pipeline dữ liệu vì các vị trí BI hiện nay yêu cầu.
- Có thể làm freelance BI sau khi xong lộ trình (dashboard, báo cáo tự động cho doanh nghiệp nhỏ).
- Thời gian học: khoảng 40 giờ/tuần, lộ trình 8 tuần (Tuần 9-10 là phần tùy chọn hướng DE).

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

## 6. Lộ trình 8 tuần (tóm tắt)
| Tuần | Nội dung chính |
|---|---|
| 1 | Mô hình dữ liệu (star schema, SCD), Python cho pipeline (API, retry, Parquet), Git, thiết lập BigQuery |
| 2 | BigQuery sâu (load job, partitioning, clustering, INFORMATION_SCHEMA, IAM), Looker Studio |
| 3 | Bật billing + kiểm soát chi phí, dbt phần 1 (source, staging, mart), Power BI kết nối BigQuery |
| 4 | dbt phần 2 (test, docs, incremental, snapshot), DAX cơ bản, bắt đầu ứng tuyển |
| 5 | Power BI nâng cao (DAX, thiết kế dashboard), hoàn thành Project 1 |
| 6 | Tự động hóa (Python API/Sheets vào BigQuery, scheduled query), chọn ngách nghiệp vụ |
| 7 | Project 2 theo ngách, đóng gói dịch vụ freelance |
| 8 | Portfolio, CV, luyện phỏng vấn |
| 9-10 | Tùy chọn: Docker, Airflow, Terraform, Spark |

Tuần 1 chi tiết: Ngày 1 thiết lập, Ngày 2 mô hình dữ liệu, Ngày 3 Python cho pipeline (1), Ngày 4 Python (2) + Git, Ngày 5 mini project (API → làm sạch → BigQuery, có logging, README), Ngày 6 ôn tập.

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


## 8. Đang làm

- **Tuần 3** (đang làm), 7 việc theo checklist: bật billing cho project `bq-learning-510104`; đặt budget alert (ngưỡng thấp) và quota bytes theo ngày; cài `dbt-bigquery`, khởi tạo project, cấu hình kết nối; khai báo source và viết staging model; viết mart model dùng `ref`; cài Power BI Desktop, kết nối BigQuery; tạo quan hệ giữa các bảng.
- **Tuần 3, Ngày 5 (kế tiếp, dự kiến theo checklist, chưa chốt chi tiết)**: cài Power BI Desktop và kết nối BigQuery, đọc `dbt_dev.fct_net_sales` và `dbt_dev.dim_products` (Import mode). Tuần 3 còn 3 việc: Power BI kết nối BigQuery, tạo quan hệ giữa các bảng, và quota (chờ nâng cấp).

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

## 10. Quyết định đã chốt
- Dùng VS Code thay vì Jupyter riêng (sẽ cần viết nhiều file `.sql`/`.yml` cho dbt).
- Chỉ học một cloud warehouse (BigQuery) cho đến khi xong lộ trình.
- Dùng một tài khoản GitHub duy nhất (`khoatranuk-sys`).
- Lưu mọi câu SQL tạo bảng vào thư mục SQL trong repo (hiện là `SQL/Day 2/`, bảng sandbox có thể hết hạn).
- Không đẩy file dữ liệu lên GitHub: `data/` đã nằm trong `.gitignore` (làm xong Ngày 3).
- Ngày 2: fact và dimension nối bằng khóa tự nhiên (`user_id`, `product_id`, `date_key`), chưa dùng surrogate key. Surrogate key và SCD Type 2 làm trên dữ liệu thật ở Tuần 4 với dbt snapshot.
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
- Sửa bullet vì sao fact_items_part chỉ còn 22.817 dòng: ghi thêm "gần như xác nhận: bảng cũ có hạn partition, tạo lại sau khi gỡ thì ra đủ 180.771".
- Thêm: có nâng cấp trả phí trước 06/01/2027 không (quyết định ~15/12/2026)?
- Giữ nguyên câu hỏi về phí làm mới MV (vẫn chưa kiểm chứng).
- Tuần 3, Ngày 2: dùng dbt Core cài bằng `pip` trong môi trường `bi`; kết nối `method: oauth`, không dùng service account hay file khóa (repo công khai). `profiles.yml` ở ngoài repo, không commit. Mọi query dbt có `maximum_bytes_billed: 1000000000`. dbt ghi vào dataset `dbt_dev` (US), tách khỏi `lab`, `dwh`, `raw`.
- Trước khi commit thư mục mới: `git status -uall` để xem từng file bên trong, bảo đảm không có `logs/`, `target/` hay file bí mật.
- Tuần 3, Ngày 3: staging model chỉ đổi tên, chọn cột, ép kiểu (không có quy tắc nghiệp vụ); staging dùng `view`. Quy tắc doanh thu chỉ tính `Complete` nằm ở tầng mart. Luôn `dbt run --select <model>`, không chạy `dbt run` trần khi còn `models/example/`.
- Số dòng của view dbt thay đổi theo bảng nguồn công khai; bảng `lab` và `dwh` là bản chụp cố định. Khi đối chiếu, so sánh trong cùng khoảng ngày rồi mới kết luận.
- Tuần 3, Ngày 4: mart đọc từ staging bằng `ref` (staging đọc bảng public), kiểu `table`: số liệu đứng yên cho đến lần `dbt run` kế tiếp, nên Power BI đọc bảng này; chạy lại một model `table` là ghi đè bản chụp cũ, không giữ lịch sử. Không đối chiếu mart với `lab.fact_items_plain` (nguồn đã lệch); đối chiếu mart với staging cùng lúc. Mart dùng `left join` và kiểm tra `cost IS NULL` + so số dòng với staging, không dùng `join` thường. Tên mart trong dbt: `fct_*` và `dim_*` (khác `fact_*` ở dataset `dwh`).

## 11. Câu hỏi còn mở
- Công cụ BI nào xuất hiện nhiều nhất trong 10-20 tin tuyển dụng quanh mình (Power BI, Tableau hay Looker Studio)?
- Ngách nghiệp vụ cho Project 2 và freelance là gì?
- Materialized view có tự cập nhật khi bảng gốc đổi không, và phí làm mới sau khi bật billing là bao nhiêu (chưa kiểm chứng).
- BigQuery có tự dùng MV khi mình hỏi trên bảng gốc không (Cell 9 Tuần 2 chỉ quét 0,04 MB, nghi là có, chưa kiểm chứng).
- Vì sao các query đọc `INFORMATION_SCHEMA.JOBS` bị tính billed 20 MB thay vì 10 MB (chưa hiểu).
- Chia sẻ dashboard Data Studio ra ngoài cần quyền gì ở BigQuery (liên quan IAM), làm sau.
- Nếu nhiều tin tuyển dụng yêu cầu Airflow/Docker thì có đưa Tuần 9-10 lên sớm không?
- Vì sao view dbt và `lab.fact_items_plain` lệch số dòng (181.466 và 180.771; chênh đổi dấu qua từng năm)? Giả thuyết là bảng nguồn công khai được cập nhật, chưa chứng minh (cần xem lại SQL tạo bảng lab ở Tuần 1).
- Mart ở Tuần 3 Ngày 4 đọc thẳng bảng public hay đọc từ một bản chụp của mình (ổn định, đối chiếu được)?
- (thêm câu hỏi khác tại đây)
- `fct_net_sales` có 45.529 dòng `Complete`, còn bản `lab` là 45.282 (chênh 247). Vẫn chưa chứng minh được là do nguồn public đổi.
- Truy vấn trên view cũng billed 10 MB (một lần đo ngày 09/10); câu có hai bảng tham chiếu thì billed 20 MB. Mới đo một lần, cần thêm lần đo để chắc.

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




