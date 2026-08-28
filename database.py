import os
import psycopg2
from dotenv import load_dotenv

# Load environment variables once when the database module is imported
load_dotenv()

def get_connection():
    """Returns a PostgreSQL connection using process environment variables."""
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        port=os.environ.get("DB_PORT", "5432"),
    )