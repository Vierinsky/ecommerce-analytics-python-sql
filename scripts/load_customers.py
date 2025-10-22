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

# Creating a relative path to sample_customers.csv
    # Run this script while located in root folder

csv_path = Path.cwd() / "data" / "sample_customers.csv"

# Mapping expected columns
expected_cols = [
    "customer_id",
    "customer_unique_id",
    "customer_zip_code_prefix",
    "customer_city",
    "customer_state"
]

# Creating a Pandas df
df = pd.read_csv(
    csv_path, 
    keep_default_na=True,    # empty strings -> NaN
    usecols=expected_cols
    )

# -------- 4) Add operational columns --------

# _ingested_at = when we loaded the row
df["_ingested_at"] = pd.Timestamp.utcnow()

# _source_file = Which file fed this row (helps trace issues later)
df["_source_file"] = os.path.basename(csv_path.name)

# _row_md5 = simple row-level checksum for idempotency/dedup in staging
# We hash a stable concatenation of key fields.

def row_hash(row) -> str:
    # We use natural keys + important fields that define the row's identity
    parts = [
        str(row["customer_id"]),
        str(row["customer_unique_id"]),
        str(row["customer_zip_code_prefix"]),
    ]

    txt = "|".join(parts)
    return hashlib.md5(txt.encode("utf-8")).hexdigest()

df["_row_md5"] = df.apply(row_hash, axis=1)

dtype_map = {
    "customer_id" : Text(),
    "customer_unique_id" : Text(),
    "customer_zip_code_prefix" : Text(),
    "customer_city" : Text(),
    "customer_state" : Text()
}

# -------- 6) Write to Postgres (staging.customers_raw) --------
# if_exists='append' so we can run it multiple times; let's use chunksize for large files

table_name = "customers_raw"
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
    res = conn.exec_driver_sql("SELECT COUNT(*) FROM staging.customers_raw;")
    count = res.scalar_one()
    print(f"Loaded rows in staging.customers_raw: {count}")

print("Done.")