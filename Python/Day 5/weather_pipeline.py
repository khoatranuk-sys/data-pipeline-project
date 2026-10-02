"""Pipeline thời tiết: gọi API -> làm sạch -> kiểm tra -> nạp BigQuery.

Chạy:  python weather_pipeline.py
Cần:   môi trường `bi` (requests, pandas, pyarrow, google-cloud-bigquery)
       và đã đăng nhập gcloud (gcloud auth application-default login).
"""
import logging
import sys
import time
from pathlib import Path

import pandas as pd
import requests
from google.cloud import bigquery

# ---------- Cấu hình ----------
PROJECT = "bq-learning-510104"
TABLE_ID = f"{PROJECT}.raw.weather_daily"
URL = "https://api.open-meteo.com/v1/forecast"
DAYS = 7
CITIES = {
    "Ha Noi": (21.03, 105.85),
    "TP HCM": (10.82, 106.63),
    "Da Nang": (16.05, 108.20),
}
SCHEMA = [
    bigquery.SchemaField("time", "DATE"),
    bigquery.SchemaField("temperature_2m_max", "FLOAT"),
    bigquery.SchemaField("temperature_2m_min", "FLOAT"),
    bigquery.SchemaField("precipitation_sum", "FLOAT"),
    bigquery.SchemaField("city", "STRING"),
    bigquery.SchemaField("ingested_at", "TIMESTAMP"),
]

# Script nằm ở Python/Day 5/, lùi 2 cấp ra gốc repo để đặt thư mục logs/
LOG_DIR = Path(__file__).resolve().parents[2] / "logs"
log = logging.getLogger("weather_pipeline")


def setup_logging():
    LOG_DIR.mkdir(exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s",
        handlers=[
            logging.StreamHandler(),
            logging.FileHandler(LOG_DIR / "weather_pipeline.log", encoding="utf-8"),
        ],
        force=True,
    )


# ---------- Extract ----------
def get_json(url, params=None, headers=None, retries=4, timeout=10):
    for attempt in range(1, retries + 1):
        try:
            r = requests.get(url, params=params, headers=headers, timeout=timeout)
        except (requests.Timeout, requests.ConnectionError) as e:
            log.warning(f"Lần {attempt}/{retries}: lỗi mạng ({type(e).__name__})")
        else:
            if r.status_code < 400:
                return r.json()
            if r.status_code != 429 and r.status_code < 500:
                raise RuntimeError(f"Lỗi {r.status_code}, không retry: {r.text[:200]}")
            log.warning(f"Lần {attempt}/{retries}: server trả {r.status_code}")
        if attempt < retries:
            wait = 2 ** attempt
            log.info(f"Chờ {wait} giây rồi thử lại")
            time.sleep(wait)
    raise RuntimeError(f"Hết {retries} lần thử: {url}")


def extract_weather(cities, days=DAYS):
    raw = {}
    for city, (lat, lon) in cities.items():
        params = {
            "latitude": lat,
            "longitude": lon,
            "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum",
            "timezone": "Asia/Ho_Chi_Minh",
            "forecast_days": days,
        }
        log.info(f"Lấy dữ liệu: {city}")
        raw[city] = get_json(URL, params=params)
        time.sleep(1)
    log.info(f"Đã lấy xong {len(raw)} thành phố")
    return raw


# ---------- Transform ----------
def transform_weather(raw):
    frames = []
    for city, data in raw.items():
        df_city = pd.DataFrame(data["daily"])
        df_city["city"] = city
        frames.append(df_city)
    df = pd.concat(frames, ignore_index=True)
    df["time"] = pd.to_datetime(df["time"]).dt.date
    df["ingested_at"] = pd.Timestamp.now(tz="UTC")
    log.info(f"Transform xong: {df.shape[0]} dòng, {df.shape[1]} cột")
    return df


def validate_weather(df, expected_cities, days=DAYS):
    problems = []

    if len(df) != expected_cities * days:
        problems.append(f"Số dòng là {len(df)}, mong đợi {expected_cities * days}")

    nulls = df.isna().sum().sum()
    if nulls > 0:
        problems.append(f"Có {nulls} giá trị thiếu")

    if df.duplicated(subset=["city", "time"]).any():
        problems.append("Có dòng trùng (city, time)")

    if (df["temperature_2m_max"] < df["temperature_2m_min"]).any():
        problems.append("Có dòng nhiệt độ max nhỏ hơn min")

    if (df["precipitation_sum"] < 0).any():
        problems.append("Có lượng mưa âm")

    if problems:
        for p in problems:
            log.error(p)
        raise ValueError("Dữ liệu không đạt kiểm tra: " + "; ".join(problems))

    log.info("Kiểm tra dữ liệu: đạt")


# ---------- Load ----------
def load_weather(df, table_id=TABLE_ID):
    client = bigquery.Client(project=PROJECT, location="US")
    job_config = bigquery.LoadJobConfig(
        schema=SCHEMA,
        write_disposition="WRITE_TRUNCATE",
    )
    log.info(f"Nạp {len(df)} dòng vào {table_id}")
    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    job.result()
    if job.output_rows != len(df):
        raise RuntimeError(f"Nạp {job.output_rows} dòng, mong đợi {len(df)}")
    log.info(f"Nạp xong: {job.output_rows} dòng")
    return job.output_rows


# ---------- Điều phối ----------
def main():
    setup_logging()
    log.info("=== Bắt đầu pipeline ===")
    start = time.time()
    try:
        raw = extract_weather(CITIES)
        df = transform_weather(raw)
        validate_weather(df, expected_cities=len(CITIES))
        load_weather(df)
    except Exception:
        log.exception("Pipeline thất bại")
        return 1
    log.info(f"=== Pipeline xong trong {time.time() - start:.1f} giây ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
