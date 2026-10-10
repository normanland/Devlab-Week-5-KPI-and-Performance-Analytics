# A/B Test Decision Note

## What I Treated As Non-Negotiable

I did not compare conversion rates until the experiment assignment was clean. A control user should see `old_page`, and a treatment user should see `new_page`. Any other combination breaks the experiment contract and was removed first.

The supplied file contains **294,478 rows**. Direct validation finds **3,893 misassigned rows (1.322%)**: 1,928 control rows landed on the new page and 1,965 treatment rows landed on the old page. The task note says 3,894, but the actual cross-tab in this CSV totals 3,893, so I used the file as the source of truth.

After assignment cleaning, one user appears twice. I kept that user's earliest valid record so the analysis remains one row per user. Final analytical population: **290,584 users**.

## Experiment Balance

| Group | Users | Share |
|---|---:|---:|
| Control | 145,274 | 49.994% |
| Treatment | 145,310 | 50.006% |

The groups differ by only **36 users**, so sample balance is not a practical concern in this descriptive comparison.

## Decision Metrics

| Metric | Control | Treatment |
|---|---:|---:|
| Users | 145,274 | 145,310 |
| Conversions | 17,489 | 17,264 |
| Conversion rate | 12.039% | 11.881% |

Treatment minus control is **-0.158 percentage points**. Relative to control, the treatment conversion rate is **-1.31%** lower.

## Time Check

The experiment spans **23 calendar dates**. Control records the higher daily conversion rate on **16 dates**; treatment leads on **7**. The mean daily treatment-minus-control gap is **-0.160 pp**.

The first and last dates are partial days, but the direction of the overall comparison is not explained by a single boundary day or an isolated spike. The daily chart shows both groups moving within a relatively narrow range throughout the run.

## Addition — Hourly Pattern

Treatment leads in **12 of 24 hourly buckets**, which means time of day creates local reversals but no stable treatment advantage. The best observed treatment gap is **+0.99 pp around 19:00**; the largest deficit is **-1.34 pp around 04:00**.

I treat this as a diagnostic rather than a causal conclusion. Hour is useful for checking whether the aggregate result hides an obvious operational window; here it does not create a compelling exception.

## Addition — Business Scale

Applying the observed rates to one million users gives approximately:

- **120,386 conversions** at the control rate
- **118,808 conversions** at the treatment rate
- **-1,578 conversions** as the treatment difference

The negative sign matters: at the observed rates, treatment would produce about **1,578 fewer conversions per million users**.

## Recommendation

**Do not launch the new page based on this descriptive test read.**

The treatment converts at **11.88%** versus **12.04%** for control. That is a **0.158 pp deficit**, and the daily stability check does not reveal a time pattern that reverses the overall conclusion.

This is deliberately not a significance claim. The assignment was to make a descriptive recommendation without statistical testing, so the decision is limited to the observed rates and their operational interpretation.

## Analytical Boundary

This notebook does not attempt to prove causality beyond the experiment setup, estimate confidence intervals, calculate p-values, or optimize the page itself. It answers one narrower question: **given the cleaned experiment data, does the new page show a better observed conversion outcome?** The answer is no.
