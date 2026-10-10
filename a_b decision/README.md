# A/B Test Decision Review

> **290,584 valid users. Two pages. One launch decision.**

This project is a descriptive read of a website A/B test. I built it around a simple rule: **the conversion gap is not trustworthy until the assignment logic is trustworthy.**

The notebook therefore starts with experiment integrity, not with a winner chart.

## Decision In One Line

**Keep the old page.**

Control converts at **12.04%** and treatment at **11.88%**. The treatment is **0.158 percentage points lower**, which translates to roughly **1,578 fewer conversions per 1M users** at the observed rates.

No statistical test is used; this is a descriptive business recommendation by design.

## Before I Compared The Pages

```text
294,478 raw rows
      ↓
3,893 assignment mismatches removed
      ↓
1 repeated user reduced to first valid exposure
      ↓
290,584 users at a clean one-user grain
      ↓
control vs treatment comparison
```

The source note mentions 3,894 mismatches. I did not copy that number into the analysis: the supplied CSV cross-tab returns **3,893**, so the project uses the dataset result.

## The Experiment On A Small Scorecard

| Signal | Result |
|---|---:|
| Control users | 145,274 |
| Treatment users | 145,310 |
| Control conversion | **12.039%** |
| Treatment conversion | **11.881%** |
| Absolute treatment gap | **-0.158 pp** |
| Relative treatment gap | **-1.31%** |
| Control-leading days | **16/23** |
| Treatment impact / 1M users | **-1,578 conversions** |

## How I Read The Result

The overall gap is small, but it is in the wrong direction for a launch. More importantly, it is not being created by an obvious sample imbalance or a single unusual date. Control has the higher daily rate on **16 of 23 dates**.

The hourly addition is deliberately a diagnostic rather than a hunt for a favorable slice. Treatment wins some hours and loses others; that variation does not overturn the aggregate outcome.

## Visual Trail

The `visuals/` folder contains:

- `assignment integrity.png` — how much raw data fails the assignment contract
- `conversion rate comparison.png` — the core control vs treatment decision view
- `daily conversion rate.png` — temporal stability check
- `conversion funnel.png` — users → converted counts for both groups
- `hourly conversion pattern.png` — bonus hour-of-day diagnostic
- `conversion yield per million.png` — observed rates translated to business scale
- `interactive hourly conversion.html` — hoverable hourly view with user and conversion counts

Visual filenames are descriptive rather than numbered so the folder remains readable as the project evolves.

## Notebook Route

```text
Decision Brief
   ↓
Integrity Gate
   ↓
Outcome Gap
   ↓
Funnel View
   ↓
Stability Over Time
   ↓
Addition: Hour-of-Day Diagnostic
   ↓
Addition: Scale the Decision
   ↓
Recommendation
```

This structure is intentionally decision-led: each section answers the question created by the previous one.

## Run It Locally

The dataset path is intentionally simple and explicit:

```python
data_path = r'C:\Users\anarrasulzada\Downloads\ab_data.csv'
df = pd.read_csv(data_path)
```

Required libraries:

```bash
pip install pandas numpy matplotlib seaborn plotly
```

Then open:

```text
ab test decision analysis.ipynb
```

and run the notebook from top to bottom.

## Files

```text
ab test decision analysis/
├── ab test decision analysis.ipynb
├── note.md
├── README.md
└── visuals/
```

The raw CSV is not duplicated inside the project folder; the notebook reads it directly from `Downloads`.

## Decision Boundary

This project does **not** claim statistical significance. It does not use a t-test, z-test, p-value, or confidence interval. The brief asks for a descriptive decision, so the recommendation is based on cleaned assignment data, observed conversion rates, time stability, and scaled business impact.
