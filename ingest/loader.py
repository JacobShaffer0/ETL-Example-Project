import os
import uuid
import pandas as pd
from sqlalchemy import text

def load_mcc_lookup(engine):
    """Reads MCC_LOOKUP.csv and performs an idempotent upsert into ref.mcc_categories."""
    csv_path = "data/MCC_LOOKUP.csv"
    if not os.path.exists(csv_path):
        print(f"ERROR: File not found at {os.path.abspath(csv_path)}")
        return

    df = pd.read_csv(csv_path)
    print(f"Reading {csv_path}: Found {len(df)} rows.")

    with engine.begin() as conn:
        for _, row in df.iterrows():
            conn.execute(text("""
                INSERT INTO ref.mcc_categories (mcc, description, category)
                VALUES (:mcc, :description, :category)
                ON CONFLICT (mcc) DO UPDATE SET
                    description = EXCLUDED.description,
                    category = EXCLUDED.category;
            """), {
                "mcc": str(row['mcc']),
                "description": row['description'],
                "category": row['category']
            })
    print("--> Successfully loaded ref.mcc_categories!")

def load_raw_transactions(engine, load_run_id=None):
    """Reads TXN_EXTRACT.csv and appends raw data into raw.transactions."""
    csv_path = "data/TXN_EXTRACT.csv"
    if not os.path.exists(csv_path):
        print(f"ERROR: File not found at {os.path.abspath(csv_path)}")
        return

    df = pd.read_csv(csv_path)
    print(f"Reading {csv_path}: Found {len(df)} rows.")

    # Use active run ID from pipeline, or fallback if run standalone
    df["load_run_id"] = load_run_id if load_run_id else str(uuid.uuid4())
    df["line_number"] = df.index + 1

    # Map CSV column headers to database table schema
    df = df.rename(columns={
        "transaction_id": "txn_id",
        "customer_id": "mbr_num",
        "transaction_timestamp": "post_dt",
        "amount": "txn_amt"
    })

    # Append records to PostgreSQL using the shared engine
    with engine.begin() as conn:
        df.to_sql("transactions", con=conn, schema="raw", if_exists="append", index=False)

    print(f"--> Successfully loaded {len(df)} rows into raw.transactions!")

def run_ingestion(engine, load_run_id=None):
    """Entry point called by run_pipeline.py, receiving the shared engine."""
    load_mcc_lookup(engine)
    load_raw_transactions(engine, load_run_id)