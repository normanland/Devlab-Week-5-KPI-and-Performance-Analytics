# KPI Framework for E-Commerce Operations

> A KPI is only useful after the join grain is proven.

This project turns nine Olist CSV files into a MySQL relational model, reconciles the analytical view, and builds operational KPIs across category, month and seller.

## The Control Point

| Revenue Path | BRL |
|---|---:|
| Direct delivered order items | **13,221,498.11** |
| Naive item × raw-review join | 13,279,836.59 |
| Fixed analytical view | **13,221,498.11** |

The raw review join adds **58,338.48 BRL** that does not exist. Reviews are reduced to one row per order before joining to item revenue.

## Framework Flow

```text
9 CSV files
   ↓
MySQL relational schema
   ↓
import + row-count readiness check
   ↓
vw_delivered_item_base
   ↓
order / category / seller grains
   ↓
Q1–Q15 SQL outputs
   ↓
pandas display + matplotlib / Plotly
```

## KPI Signal Board

| Signal | Result |
|---|---:|
| Delivered revenue | **13.22M BRL** |
| AOV | **137.04 BRL** |
| Avg delivery | **12.50 days** |
| Avg review | **4.16 / 5** |
| On-time delivery | **93.23%** |
| No-review share | **0.670%** |
| Delivery vs review correlation | **-0.499** |
| Top-10 seller revenue share | **13.27%** |

## Why MySQL Could Show No Useful Result

Creating the tables does not import the CSV rows. If Q1 returns zero or tiny counts, the schema exists but the data is missing or partially loaded.

The corrected notebook now:

1. creates the database/tables from `queries.sql` if needed;
2. checks every source table against the expected row count;
3. imports an empty table from `C:\Users\anarrasulzada`;
4. stops on a partial import instead of silently continuing;
5. creates the analytical view;
6. runs Q1–Q15 against MySQL.

A correct readiness check includes **99,441 orders**, **112,650 order-item rows** and **99,224 review rows**.

## Query Map

Q1 covers table counts/cardinality; Q2 the view and join audit; Q3 reconciliation; Q4 core KPIs; Q5 category KPIs; Q6 monthly KPIs; Q7/Q8 ranked segments with a minimum 100-order threshold; Q9 seller ranking; Q10 delivery vs satisfaction; Q11–Q14 all bonus requirements; Q15 is the seller-concentration addition.

SQL keywords remain lowercase. No `q start` / `q end` markers are used.

## Required Visuals

The notebook directly creates the three required charts from SQL results:

- monthly revenue trend;
- top/bottom five revenue categories;
- delivery days vs review score with a trend line.

Additional visuals cover seller reliability, freight pressure, category-mix movement and on-time delivery.

