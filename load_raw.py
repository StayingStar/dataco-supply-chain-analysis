"""Copy the raw CSV into PostgreSQL as raw_orders. Safe to run again."""
import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()
engine = create_engine(os.environ["ADMIN_DB_URL"])

raw = pd.read_csv("data/dataco_utf8.csv")
print(f"Read {len(raw):,} rows and {raw.shape[1]} columns from the CSV")

raw.to_sql("raw_orders", engine, if_exists="replace", index=False, chunksize=10000)
print("Loaded into table raw_orders")