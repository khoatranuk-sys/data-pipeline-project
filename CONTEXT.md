# Ngữ cảnh học tập (dán file này vào đầu mỗi cuộc trò chuyện mới)

> Cập nhật lần cuối: 02/10/2026. Cuối mỗi ngày học, sửa mục "Đã hoàn thành", "Đang làm" và "Lỗi đã gặp" rồi commit.
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
- **Biến đổi dữ liệu**: dbt (bắt đầu Tuần 3).
- **BI**: Power BI (giả định, cần đối chiếu với tin tuyển dụng quanh mình), kèm Looker Studio để có dashboard sớm.
- **Ưu tiên thấp (để sau)**: Airflow, Docker, Spark, Terraform. Với BI, scheduled query và lịch làm mới của công cụ BI thường là đủ.

## 4. Môi trường trên máy
- Windows, VS Code (dùng cả notebook `.ipynb` và script `.py`).
- Anaconda, môi trường `bi` (Python 3.11). Mỗi lần làm việc: `conda activate bi`, trong VS Code chọn interpreter/kernel `bi`. Đã kiểm tra có sẵn `requests`, `pandas`, `pyarrow`.
- Thư mục repo trên máy: `D:\BI\projects\data-pipeline-project`. Vào bằng Anaconda Prompt: `cd /d "D:\BI\projects\data-pipeline-project"` rồi `code .` (phải có `/d` vì repo nằm ổ D:).
- gcloud CLI đã cài và xác thực (`gcloud auth application-default login`).
- Git đã cài, cấu hình `user.email` bằng email noreply của GitHub.
- Repo GitHub: `data-pipeline-project` (Public), tài khoản `khoatranuk-sys`.
- Google Cloud project: `bq-learning-510104`, location dữ liệu là **US**, hiện dùng **sandbox** (chưa bật billing).
- Theo dõi tiến độ bằng file Excel checklist (`lo_trinh_BI_checklist.xlsx`).
- Cấu trúc repo thực tế (tên thư mục viết hoa): `SQL/Day 2/` (file SQL và notebook Ngày 2), `Python/Day 3/` (notebook `Day3.ipynb`), `Doc/` (ảnh sơ đồ), `Notes.md` (ghi chú các ngày), `CONTEXT.md`, `data/` (file dữ liệu tạo ra khi chạy code, **không commit**, nằm trong `.gitignore`).
- Cách chạy query trong notebook VS Code: hai hàm dùng chung `check(sql)` (dry run, chỉ in số MB sẽ quét) và `run(sql, max_mb=100)` (chạy thật, giới hạn `maximum_bytes_billed`). Mỗi truy vấn một cell: gán `sql`, chạy `check`, thấy nhỏ rồi mới chạy `df = run(sql)`.
- Notebook gọi API (Ngày 3) lưu file ra `Path("../../data")` (notebook nằm ở `Python/Day 3/`, lùi hai cấp ra gốc repo).
- Từ Ngày 4: thêm `Python/Day 4/` (notebook `Day4.ipynb`), `.env` (khóa giả để tập, **không commit**, bị `.gitignore` chặn ở dòng 151) và `.env.example` (file mẫu, có commit). Dataset `bq-learning-510104.raw` (US) chứa dữ liệu thô từ API.
- Terminal VS Code (PowerShell) dùng Python của `base`, không phải `bi`; `conda activate bi` trong PowerShell không có tác dụng. Kernel notebook mới là môi trường `bi`, nên cài thư viện bằng `%pip install ...` trong notebook. Lệnh Git thì không phụ thuộc môi trường Python.
- Khi gõ lệnh, tên nhánh, tên file: tắt bộ gõ tiếng Việt.
- Pipeline chạy bằng một lệnh: `D:\Installsoftware\Anaconda\envs\bi\python.exe "Python\Day 5\weather_pipeline.py"` (dùng đường dẫn đầy đủ tới Python của `bi`; gõ `python` trong terminal VS Code sẽ dùng `base` và báo thiếu `google.cloud`). Log ghi ra `logs/weather_pipeline.log` (bị `.gitignore` chặn).

## 5. Chi phí và an toàn
- Bật billing vào đầu **Tuần 3** (dbt cần DML; sandbox có bảng tự hết hạn sau 60 ngày).
- Khi bật billing phải đặt ngay: budget alert (ngưỡng thấp) và quota bytes query theo ngày.
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

## 8. Đang làm
- **Tuần 2** (BigQuery nâng cao + Looker Studio), 7 việc theo checklist: nạp CSV/Parquet bằng load job (giao diện và Python, thử `load_table_from_uri`); tạo bảng partition theo ngày và so sánh bytes quét trước/sau; thêm clustering và đo lại chi phí; đọc `INFORMATION_SCHEMA.JOBS` để theo dõi chi phí từng query; học IAM cơ bản, view, materialized view; kết nối Looker Studio với BigQuery; dựng dashboard đầu tiên (KPI, biểu đồ, bộ lọc).
- Việc cụ thể đang vướng: Git còn chưa chắc (khác nhau giữa `add` và `commit`, vì sao phải `git pull` sau khi merge); cần lặp lại nhiều lần mới quen. Cảnh báo `pandas-gbq` chưa xử lý (không bắt buộc).
- Gợi ý khi vào Tuần 2: partition và clustering sẽ giải thích tận gốc vì sao `LIMIT` không giảm chi phí, nên nối tiếp trực tiếp câu `SELECT *` của Ngày 6.

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

## 11. Câu hỏi còn mở
- Công cụ BI nào xuất hiện nhiều nhất trong 10-20 tin tuyển dụng quanh mình (Power BI, Tableau hay Looker Studio)?
- Ngách nghiệp vụ cho Project 2 và freelance là gì?
- Đơn trạng thái `Processing` và `Shipping` (chưa hoàn tất) có tính vào doanh thu không? Cần chốt quy tắc và ghi lại để các báo cáo nhất quán.
- Nếu nhiều tin tuyển dụng yêu cầu Airflow/Docker thì có đưa Tuần 9-10 lên sớm không?
- (thêm câu hỏi khác tại đây)

## 12. Cách mình muốn được trả lời
- Tiếng Việt, từng bước rõ ràng, lệnh gõ nguyên văn (mình dùng Windows).
- Nói rõ nơi chạy lệnh (Anaconda Prompt, VS Code, hay BigQuery web).
- Mình thường gửi ảnh chụp màn hình khi vướng, hãy đọc kỹ ảnh trước khi kết luận.
- Cảnh báo trước nếu một bước có thể tốn tiền hoặc khó hoàn tác.
- Khi mình đã hoàn thành một ngày, chỉ cần nội dung ngày kế tiếp, không lặp lại phần cũ.
- Nói rõ điều gì chưa chắc chắn thay vì đoán.
- Với phần code mới: giải thích mỗi bước để làm gì và dịch sang SQL khi có thể; nói rõ phần nào cần hiểu, phần nào không cần thuộc. Chia nhỏ từng cell, mỗi cell kèm kết quả mong đợi.
