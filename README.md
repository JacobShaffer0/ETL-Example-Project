Requirements - 
Python: 3.9+
PostgreSQL: 13+
Python Libraries: pandas and psycopg2

Generate Mock Data -

Run generate_data.py to create mock transaction CSV. You can adjust the number of
transactions and members on line 34.

Run the Pipeline

run_pipeline.py Executes the ingestion, staging, production upsert, and metrics generation.

Run genereate_data.py first and then run pipeline.py to use the program. 

1. Ensures that running the pipeline multiple times with the same dataset produces the  same system state without causing duplicate records, errors, or system failure.

2. Using ROW_NUMBER() assigns a sequence integer to every record per primary key which allows the pipeline to select only where row_num = 1 and discard identical records.

3. Turns the insertion into an upsert, allowing the query to modify changed attributes instead of throwing a violation.

4. Created_at records the immutable timestamp when a transaction was first inserted into the database.

Updated_at records the timestamp of the most recent modification or backfill.
Having both provides the ability for people to check the data history. 

5. Prevents the ingestion layer from crashing due to malformed dates, unexpected currency symbols, or unexpected string inputs.

6. Using a join allows the mappings to be dynamically updated.