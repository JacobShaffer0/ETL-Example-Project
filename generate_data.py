import csv
import random
import uuid
from datetime import datetime, date

def generate_random_date(start_year=2020, end_year=2026):
    year = random.randint(start_year, end_year)
    month = random.randint(1, 12)
    
    # Determine maximum valid day for the generated month/year
    if month in [1, 3, 5, 7, 8, 10, 12]:
        max_day = 31
    elif month in [4, 6, 9, 11]:
        max_day = 30
    else:
        # Leap year check for February
        is_leap = (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0))
        max_day = 29 if is_leap else 28
        
    day = random.randint(1, max_day)
    return date(year, month, day)

def generate_mock_transactions(filename="data/TXN_EXTRACT.csv", num_records=6000, num_members=100):
    load_run_id = str(uuid.uuid4())
    
    # Pre-generate 100 fixed member IDs
    member_ids = [f"MBR_{100 + i}" for i in range(num_members)]
    
    mcc_codes = ["5100", "5200", "5300", "5400", "5812", "5912"]
    merchants = ["Target", "Walmart", "Starbucks", "Amazon", "Chevron", "Costco"]
    
    with open(filename, mode="w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow([
            "line_number", "load_run_id", "txn_id", "mbr_num", "acct_num", 
            "post_dt", "txn_amt", "dr_cr_cd", "mcc", "merch_nm", "txn_desc",
            "txn_seq_num", "proc_dt", "batch_id"
        ])
        
        for i in range(1, num_records + 1):
            txn_id = f"TXN_{10000 + i}"
            mbr_num = random.choice(member_ids)
            acct_num = f"ACCT_{random.randint(1000, 9999)}"
            
            # Random date spanning 2020-2026 across all months
            dt_obj = generate_random_date(2020, 2026)
            post_dt = dt_obj.strftime("%Y%m%d")
            
            txn_amt = round(random.uniform(5.0, 750.0), 2)
            dr_cr_cd = random.choice(["D", "C"])
            mcc = random.choice(mcc_codes)
            merch_nm = random.choice(merchants)
            txn_desc = f"Purchase at {merch_nm}"
            
            txn_seq_num = f"SEQ_{i:06d}"
            proc_dt = post_dt
            batch_id = f"BATCH_{random.randint(10, 99)}"
            
            writer.writerow([
                i, load_run_id, txn_id, mbr_num, acct_num, 
                post_dt, txn_amt, dr_cr_cd, mcc, merch_nm, txn_desc,
                txn_seq_num, proc_dt, batch_id
            ])
            
    print(f"Successfully generated {num_records} mock records across {num_members} members (2020-2026) in {filename}")

if __name__ == "__main__":
    generate_mock_transactions()