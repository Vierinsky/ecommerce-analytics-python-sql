from dotenv import load_dotenv
import hashlib
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.types import Text, Integer, Numeric
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
csv_path = Path.cwd() / "data" / "sample_order_items.csv"

# Mapping expected columns
expected_cols = [
    "order_id",
    "order_item_id",
    "product_id",
    "seller_id",
    "price",
    "freight_value"
]

# Creating a Pandas df
sample_orders = pd.read_csv(
    csv_path, 
    parse_dates=date_cols, 
    keep_default_na=True,    # empty strings -> NaN
    usecols=expected_cols
    )

# -------- 4) Add operational columns --------

# _ingested_at = when we loaded the row
sample_orders["_ingested_at"] = pd.Timestamp.utcnow()

# _source_file = Which file fed this row (helps trace issues later)
sample_orders["_source_file"] = os.path.basename(csv_path)

# _row_md5 = simple row-level checksum for idempotency/dedup in staging
# We hash a stable concatenation of key fields.

def row_hash(row) -> str:
    # We use natural keys + important fields that define the row's identity
    parts = [
        str(row["order_id"]),
        str(row["product_id"]),
        str(row["seller_id"]),
    ]

    txt = "|".join(parts)
    return hashlib.md5(txt.encode("utf-8")).hexdigest()

sample_orders["_row_md5"] = sample_orders.apply(row_hash, axis=1)

# -------- 5) Map pandas dtypes to SQL column types (optional) --------
# This helps Postgres store correct types. Matches staging.orders_raw DDL.

dtype_map = {
    "order_id" : Text(),
    "order_item_id" : Integer(),
    "product_id" : Text(),
    "seller_id" : Text(),
    "price" : Numeric(),
    "freight_value" : Numeric()
}

# -------- 6) Write to Postgres (staging.orders_raw) --------
# if_exists='append' so we can run it multiple times; let's use chunksize for large files
