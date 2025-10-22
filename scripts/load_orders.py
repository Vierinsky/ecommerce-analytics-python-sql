from dotenv import load_dotenv
import hashlib
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.types import Text, DateTime, Numeric
import pandas as pd
from pathlib import Path
import os

# -------- 1) Load environment variables (.env) --------

# This allows to change credentials without changing code.
load_dotenv()

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "")
DB_NAME = os.getenv("DB_NAME", "ecom")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))

# -------- 2) Build the SQLAlchemy engine URL --------

# Connecting to "ecom" DB
url = URL.create(
    "postgresql+psycopg2",
    username=DB_USER,
    password=DB_PASS,
    host=DB_HOST,
    port=DB_PORT,
    database=DB_NAME
)

# Creating engine
engine = create_engine(url, echo=False, pool_pre_ping=True, future=True)

# -------- 3) Load the CSV with pandas --------

# Creating a relative path to sample_orders.csv
    # Run this script while located in root folder
csv_path = Path.cwd() / "data" / "sample_orders.csv"

# Mapping date columns' names
date_cols = [
    # "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_customer_date",
    "order_estimated_delivery_date"
]

# Mapping expected columns
expected_cols = [
    "order_id",
    "customer_id",
    "order_status",
    # "order_purchase_timestamp",   # Let's evaluate if we end up incorporating this column.
    "order_approved_at",
    "order_delivered_customer_date",
    "order_estimated_delivery_date"
]

# Creating a Pandas df
df = pd.read_csv(
    csv_path, 
    parse_dates=date_cols, 
    keep_default_na=True,    # empty strings -> NaN
    usecols=expected_cols
    )

# -------- 4) Add operational columns --------

# _ingested_at = when we loaded the row
df["_ingested_at"] = pd.Timestamp.utcnow()

# _source_file = Which file fed this row (helps trace issues later)
df["_source_file"] = csv_path.name

# _row_md5 = simple row-level checksum for idempotency/dedup in staging
# We hash a stable concatenation of key fields.

def row_hash(row) -> str:
    # We use natural keys + important fields that define the row's identity
    parts = [
        str(row["order_id"]),
        str(row["customer_id"]),
        str(row["order_status"]),
        # We use ISD format for datetimes to make deterministic strings
        row["order_approved_at"].isoformat() if pd.notna(row["order_approved_at"]) else "",
        row["order_delivered_customer_date"].isoformat() if pd.notna(row["order_delivered_customer_date"]) else "",
        row["order_estimated_delivery_date"].isoformat() if pd.notna(row["order_estimated_delivery_date"]) else "",
    ]
    txt = "|".join(parts)
    return hashlib.md5(txt.encode("utf-8")).hexdigest()

df["_row_md5"] = df.apply(row_hash, axis=1)

# -------- 5) Map pandas dtypes to SQL column types (optional) --------
# This helps Postgres store correct types. Matches staging.orders_raw DDL.

dtype_map = {
    "order_id": Text(),
    "customer_id" : Text(),
    "order_status"  : Text(),
    # "order_purchase_timestamp" : DateTime(),
    "order_approved_at" : DateTime(),
    "order_delivered_customer_date" : DateTime(),
    "order_estimated_delivery_date" : DateTime(),
    "_ingested_at" : DateTime(),
    "_source_file" : Text(),
    "_row_md5" : Text()
}

# -------- 6) Write to Postgres (staging.orders_raw) --------
# if_exists='append' so we can run it multiple times; let's use chunksize for large files

table_name = "orders_raw"
schema_name = "staging"

with engine.begin() as conn: # begin() = transaction; commits or rolls back automatically
    # Optional: simple dedup strategy per file — delete rows with same _source_file first
    # This makes reruns idempotent for the same CSV. Comment out if you prefer pure append.

    conn.exec_driver_sql(
        f"DELETE FROM {schema_name}.{table_name} WHERE _source_file = %(src)s",
        {"src": csv_path.name},
    )

    df.to_sql(
        name=table_name,
        con=conn,
        schema=schema_name,
        if_exists="append",
        index=False,
        dtype=dtype_map,
        method="multi",     # batched inserts
        chunksize=1_000,    # can be adjusted
    )

# -------- 7) Quick verification query --------

with engine.connect() as conn:
    res = conn.exec_driver_sql("SELECT COUNT(*) FROM staging.orders_raw;")
    count = res.scalar_one()
    print(f"Loaded rows in staging.orders_raw: {count}")

print("Done.")