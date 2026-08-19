#!/usr/bin/env python3
"""Build the SQLite model and Power BI-ready CSV outputs using only stdlib."""
from pathlib import Path
import csv
import sqlite3

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data/raw/telco_customer_churn.csv"
DB = ROOT / "data/churn.db"
OUT = ROOT / "outputs"

COLS = [
    "customer_id", "gender", "senior_citizen", "partner", "dependents", "tenure",
    "phone_service", "multiple_lines", "internet_service", "online_security",
    "online_backup", "device_protection", "tech_support", "streaming_tv",
    "streaming_movies", "contract", "paperless_billing", "payment_method",
    "monthly_charges", "total_charges", "churn"
]

def export(conn, query, path):
    cur = conn.execute(query)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([d[0] for d in cur.description])
        writer.writerows(cur)

def main():
    if not RAW.exists():
        raise SystemExit(f"Missing {RAW}. See README for the download command.")
    DB.unlink(missing_ok=True)
    conn = sqlite3.connect(DB)
    conn.executescript((ROOT / "sql/01_schema.sql").read_text())
    with RAW.open(newline="", encoding="utf-8-sig") as f:
        rows = []
        for row in csv.DictReader(f):
            vals = list(row.values())
            vals[2], vals[5] = int(vals[2]), int(vals[5])
            vals[18] = float(vals[18])
            vals[19] = float(vals[19]) if vals[19].strip() else None
            rows.append(vals)
    placeholders = ",".join("?" for _ in COLS)
    conn.executemany(f"INSERT INTO raw_customers VALUES ({placeholders})", rows)
    conn.executescript((ROOT / "sql/02_model.sql").read_text())
    OUT.mkdir(exist_ok=True)
    export(conn, "SELECT * FROM customer_risk_export ORDER BY risk_score DESC", OUT / "customer_risk_scores.csv")
    export(conn, "SELECT * FROM validation_by_tier", OUT / "validation_by_tier.csv")
    export(conn, "SELECT * FROM signal_weights ORDER BY weight DESC", OUT / "signal_weights.csv")
    export(conn, "SELECT risk_tier, top_risk_reason, COUNT(*) customers, ROUND(100.0*AVG(churned),1) churn_rate_pct FROM customer_scores GROUP BY 1,2 ORDER BY 1,3 DESC", OUT / "risk_reason_summary.csv")
    checks = {
        "rows": conn.execute("SELECT COUNT(*) FROM raw_customers").fetchone()[0],
        "duplicate_ids": conn.execute("SELECT COUNT(*)-COUNT(DISTINCT customer_id) FROM raw_customers").fetchone()[0],
        "invalid_churn": conn.execute("SELECT COUNT(*) FROM raw_customers WHERE churn NOT IN ('Yes','No')").fetchone()[0],
        "missing_total_charges": conn.execute("SELECT COUNT(*) FROM raw_customers WHERE total_charges IS NULL").fetchone()[0],
    }
    print("Build complete:", checks)
    print("Validation (held-out 20%):")
    for row in conn.execute("SELECT * FROM validation_by_tier"):
        print(row)
    conn.close()

if __name__ == "__main__":
    main()

