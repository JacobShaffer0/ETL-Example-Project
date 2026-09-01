This program is an end-to-end, PostgreSQL pipeline. This pipeline ingests raw banking transaction data, validates the data and dedeuplicates into a clean staging environment, performs an upsert into production, and computes windowed spending analytics.

Requirements - 
Python 
Postgres

Run pipeline.py to use the program.

1. idempotency ensures that running the same data twice doesn't crash the entire system. Pipelines should not crash from being reran.

2. using ROW_NUMBER() assigns a sequence integer to every record per primary key which allows the pipeline to select only where row_num = 1 and discrad identical records.

3. on conflict does not fail if there is an id is dupicated as insert would. 

4. created_at records the immutable timestamp when a transaction was first inserted into the database.

updated_at records the timestamp of the most recent modification or backfill.
Having both provides the abiloty for people to check the data history. 

5. prevents the ingestion layer from crashing due to malformed dates, unexpected currency symbols, or unexpected string inputs.

6. using a join allows the mappings to be dynamically updated.