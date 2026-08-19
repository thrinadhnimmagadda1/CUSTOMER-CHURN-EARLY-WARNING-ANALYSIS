DROP TABLE IF EXISTS raw_customers;

CREATE TABLE raw_customers (
  customer_id TEXT PRIMARY KEY,
  gender TEXT,
  senior_citizen INTEGER,
  partner TEXT,
  dependents TEXT,
  tenure INTEGER,
  phone_service TEXT,
  multiple_lines TEXT,
  internet_service TEXT,
  online_security TEXT,
  online_backup TEXT,
  device_protection TEXT,
  tech_support TEXT,
  streaming_tv TEXT,
  streaming_movies TEXT,
  contract TEXT,
  paperless_billing TEXT,
  payment_method TEXT,
  monthly_charges REAL,
  total_charges REAL,
  churn TEXT
);

