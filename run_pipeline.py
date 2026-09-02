import os
import uuid
import importlib.util
from psycopg2.extras import RealDictCursor
from sqlalchemy import create_engine
from database import get_connection

def execute_sql_file(cur, filepath):
    # Reads and executes a SQL file using the active cursor
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"SQL file not found at {filepath}")
    with open(filepath, "r") as f:
        sql_content = f.read()
    cur.execute(sql_content)

def run_pipeline():
    load_run_id = str(uuid.uuid4())
    print(f"Starting ETL Pipeline Run | ID: {load_run_id}")

    db_url = f"postgresql://{os.environ['DB_USER']}:{os.environ['DB_PASSWORD']}@{os.environ['DB_HOST']}:{os.environ.get('DB_PORT', '5432')}/{os.environ['DB_NAME']}"
    engine = create_engine(db_url)

    try:
        # Open connection context
        conn = get_connection()
        with conn.cursor(cursor_factory=RealDictCursor) as cur:

            # Ingest Raw CSV Data
            print("1. Running Data Ingestion (Layer 1)...")
            loader_path = os.path.join("ingest", "loader.py")

            if os.path.exists(loader_path):
                spec = importlib.util.spec_from_file_location("loader", loader_path)
                loader_module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(loader_module)

                # Pass engine and load_run_id to loader.py
                if hasattr(loader_module, "run_ingestion"):
                    loader_module.run_ingestion(engine, load_run_id)
                else:
                    raise AttributeError("ingest/loader.py is missing the 'run_ingestion(engine, load_run_id)' function.")
            else:
                raise FileNotFoundError(f"Loader script not found at {loader_path}")

            print("-> Ingestion completed.\n")

            # Stage and Validate Data
            print("Staging and Validating Data.")
            stage_script = os.path.join("sql", "stage.sql")
            execute_sql_file(cur, stage_script)
            print("-> Staging completed.\n")

            # Load into Production Tables
            print("Upserting clean records to production")
            load_script = os.path.join("sql", "load.sql")
            execute_sql_file(cur, load_script)
            print("-> Production load completed.\n")

            # Refresh Analytics Views
            print("Refreshing Layer 4 Analytics View")
            analytics_script = os.path.join("analytics", "analytics.v_monthly_member_summary.sql")
            if os.path.exists(analytics_script):
                execute_sql_file(cur, analytics_script)
            print("-> Analytics refresh completed.\n")

            # Commit transaction across stages
            conn.commit()

            #Print Run Summary Metrics
            print("PIPELINE RUN SUMMARY")

            cur.execute(
                "SELECT COUNT(*) AS cnt FROM raw.transactions WHERE load_run_id = %s;",
                (load_run_id,)
            )
            raw_count = cur.fetchone()["cnt"]

            # Staging count
            cur.execute("SELECT COUNT(*) AS cnt FROM staging.transactions;")
            stg_count = cur.fetchone()["cnt"]

            print(f"Rows Ingested (Raw)   : {raw_count}")
            print(f"Rows Staged (Valid)   : {stg_count}")

    except Exception as e:
        if 'conn' in locals() and conn:
            conn.rollback()
        print(f"\nPipeline execution failed: {e}")
    finally:
        if 'conn' in locals() and conn:
            conn.close()

if __name__ == "__main__":
    run_pipeline()