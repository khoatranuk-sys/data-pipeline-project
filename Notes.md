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