# End-to-End KPI Framework — Technical Note

## Scope And Engine

The project uses the programme's recommended **Olist Brazilian E-Commerce** dataset. All nine supplied CSV files are modelled.

The implementation engine is **MySQL 8+**, following the workflow used for this submission. The required relational features — CTEs, window functions, views, `having`, inner/left/anti-joins — are implemented with MySQL equivalents.

## Data Readiness

The notebook verifies the import instead of assuming it succeeded. Expected source counts are 99,441 orders, 112,650 order-item rows, 99,224 review rows, 32,951 products, 3,095 sellers, 99,441 customers, 103,886 payment rows, 1,000,163 geolocation rows and 71 category translations.

If a table is empty, the notebook imports it. If a table is partially loaded, the notebook stops rather than analysing incomplete data.

## ER Sketch

```text
olist_customers
PK customer_id
      │ 1
      └────────────< N  olist_orders
                      PK order_id
                      FK customer_id
                         │ 1
            ┌────────────┼─────────────┐
            │ N          │ N           │ N
            ▼            ▼             ▼
olist_order_items   olist_order_reviews   olist_order_payments
PK (order_id,       PK (review_id,        PK (order_id,
    order_item_id)      order_id)             payment_sequential)
FK product_id
FK seller_id
      │
      ├──────────────> olist_products
      │                  PK product_id
      │                       │
      │                       ▼
      │              category translation
      │              PK product_category_name
      │
      └──────────────> olist_sellers
                         PK seller_id

olist_geolocation
surrogate PK geolocation_id
```

## Join Contract

The analytical view is one row per delivered `order_id + order_item_id`.

| Stage | Join | Rows | Distinct Orders | Unmatched |
|---|---|---:|---:|---:|
| delivered orders | filter | 96,478 | 96,478 | 0 |
| order items | `inner join` | 110,197 | 96,478 | 0 |
| products | `left join` | 110,197 | 96,478 | 0 |
| translation | `left join` | 110,197 | 96,478 | 1,559 item rows |
| review aggregate | `left join` | 110,197 | 96,478 | 646 orders |
| sellers | `left join` | 110,197 | 96,478 | 0 |

`orders → order_items` uses an `inner join` because revenue requires item facts. Enrichment tables use `left join` so missing descriptive data does not delete commercial rows. Reviews are aggregated to one row per order before the item-grain join. Q12 uses a `left join ... where r.order_id is null` anti-join.

## Q3 Reconciliation — Mandatory Control

| Method | Revenue (BRL) | Difference |
|---|---:|---:|
| direct delivered order items | 13,221,498.11 | 0.00 |
| naive raw-review join | 13,279,836.59 | +58,338.48 |
| fixed analytical view | 13,221,498.11 | 0.00 |

The naive review join inflates revenue by **0.4412%**. The fixed view aggregates reviews before joining, so revenue reconciles exactly.

## KPI Checkpoints

| KPI | Result |
|---|---:|
| delivered orders | 96,478 |
| total product revenue | 13,221,498.11 BRL |
| AOV | 137.04 BRL |
| average delivery time | 12.50 days |
| average review score | 4.16 / 5 |
| on-time delivery rate | 93.23% |
| no-review share | 0.670% |
| category delivery/review correlation | -0.4989 |
| top-10 seller revenue share | 13.27% |

The reference note's ~13.59M BRL is the all-status item total. The acceptance criterion requires delivered orders only.

## Ranked Segments

Q7 and Q8 both suppress low-volume categories with:

```sql
having count(distinct order_id) >= 100
```

The bottom-five revenue categories after the threshold are `christmas_supplies`, `fashion_underwear_beach`, `fashion_male_clothing`, `food_drink`, and `books_technical`.

## Bonus Layer

### On-Time Delivery

Q11 compares **dates**, not raw timestamps, and averages after reducing the item view to one row per order. Overall on-time performance is **93.23%**.

### Missing Reviews

Q12 uses an anti-join. **646 of 96,478** delivered orders have no review: **0.670%**.

### Freight Pressure

Q13 uses `sum(freight_value) / sum(price)` as a shipping-burden proxy, not accounting margin. Among categories with at least 100 orders, `christmas_supplies` is 36.52%, `signaling_and_security` 30.39%, and `electronics` 29.46%.

### Monthly Category Mix

Q14 calculates category share of monthly revenue with a window function. Pandas only reshapes the SQL result for visualization.

## Five Operational Insights

### 1. Q3 — Join Integrity Is A Financial Control

The naive review join adds **58,338.48 BRL (+0.4412%)** that is not present in the delivered item facts.

**Action:** keep review data at order grain before joining item revenue.

### 2. Q6 + Q11 — Revenue Peaks Can Become Service Pressure

Delivered revenue peaks at **987,765.37 BRL in 2017-11**; the month also has about **15.07 delivery days** and a **3.99 review score**.

**Action:** combine demand planning with fulfilment capacity.

### 3. Q10 — Slower Delivery Tracks Lower Ratings

Category averages have **r = -0.499**. `office_furniture` is a pressure point at roughly 20.59 delivery days, 3.64 review score, 1,254 orders and 268,154.31 BRL revenue.

**Action:** prioritize slow categories with meaningful scale.

### 4. Q9 + Q15 — Revenue Rank Is Not Seller Quality

The top 10 sellers contribute **13.27%** of delivered product revenue. The fifth-ranked seller generates **186,570.05 BRL** while averaging about **22.29 delivery days** and **3.50 review score**.

**Action:** combine commercial rank with service KPIs.

### 5. Q13 — Freight Is An Operational Pressure Signal

Overall freight is about **16.63%** of delivered product revenue.

**Action:** review carrier mix, packaging and regional fulfilment where freight pressure remains high.
