# Technical Note — YouTube Engagement Analytics

## Analytical Contract

The source contains **40,949 trending snapshots** but only **6,351 unique videos**. The analysis therefore follows the task's explicit grain rule: sort by `trending_date` and keep the **first trending appearance per `video_id`**.

`US_category_id.json` is used as a lookup dimension to decode `category_id` into readable `category_name` values. No category IDs used by the US first-appearance dataset remain unmapped.

## Metric Definitions

| Metric | Definition | Interpretation |
|---|---|---|
| `engagement_rate` | `(likes + dislikes + comment_count) / views × 100` | interactions relative to reach |
| `like_rate` | `likes / views × 100` | positive-response intensity |
| `days_to_trend` | first `trending_date` − publication calendar date | trend-entry velocity |
| `tag_count` | pipe-separated tag count | metadata-density addition |

Publication timestamps are converted from UTC timestamps to calendar dates before `days_to_trend` is calculated. This avoids fractional-day artifacts.

## Data Quality Notes

- missing category names: **0**
- zero-view rows after deduplication: **0**
- negative `days_to_trend`: **0**
- comments disabled: **101** videos
- ratings disabled: **26** videos
- video error / removed flag: **3** videos

Disabled interaction features are preserved rather than filtered. They are part of the observed trending snapshot, but they can suppress measured engagement and should be remembered during interpretation.

## Correlation Results At The Required Grain

| Relationship | Pearson r |
|---|---:|
| views ↔ likes | **0.761** |
| likes ↔ comments | **0.806** |
| dislikes ↔ comments | **0.680** |
| views ↔ engagement rate | **0.057** |
| engagement rate ↔ days to trend | **-0.104** |

The provided task note reports approximately `views ↔ likes = 0.84` and `comments ↔ dislikes = 0.71`. Those values are close to the **all-snapshot** correlations in the supplied file (0.849 and 0.700). After applying the task's required first-appearance deduplication, they become **0.761** and **0.680**. This difference is documented rather than forced to match the reference note.

## Category Benchmarks

Among categories with at least 50 first-appearance videos:

- highest average views: **Music — 1.39M**
- highest average engagement rate: **Music — 8.23%**
- Howto & Style engagement rate: **5.97%**
- Comedy engagement rate: **5.69%**

Very small categories such as `Shows` and `Nonprofits & Activism` are retained in required tables but are not used as headline strategy winners because their sample sizes are limited.

## Publishing Pattern

- highest **mean** first-appearance views: **Friday — 0.89M**
- highest **median** first-appearance views: **Sunday — 297K**

The required boxplot uses a log view axis because the distribution is strongly right-skewed. Weekday groups overlap substantially, so this analysis supports a scheduling signal rather than a causal weekday claim.

## Top-10 Reach Profile

The top 10 first-appearance videos are split between **6 Music** and **4 Entertainment** entries. The highest first-appearance view count is **48.43M**.

## Addition — Audience Archetypes

Quartile thresholds produce:

- **passive reach:** 335 videos — top-quartile views + bottom-quartile engagement
- **niche loyalty:** 352 videos — bottom-quartile views + top-quartile engagement

These segments separate audience scale from audience intensity and are visualized both statically and interactively.

## Addition — Trend Velocity

For high-volume categories, typical first trend entry is usually **1–2 days** after publication. Means are much larger for some categories because the source contains a long tail of older videos resurfacing. Median and 75th-percentile windows are therefore more representative for launch planning.

## Addition — Metadata Density

`tag_count` has a Pearson correlation of **0.042** with views and **-0.038** with engagement rate. In this first-appearance dataset, more tags are not a meaningful standalone performance signal.

## Five Content Strategy Insights

1. **Music wins on both reach and response at first trend entry.** It leads average views and average engagement among meaningful-volume categories; creators should not assume mass reach requires low engagement.
2. **Interaction volume and normalized engagement answer different questions.** `likes ↔ comments` is strong, while `views ↔ engagement_rate` is close to zero. Reach goals and community-response goals need separate KPIs.
3. **Grain control changes conclusions.** Keeping repeated trending snapshots raises several correlations, including `views ↔ likes` from 0.761 to 0.849. One-row-per-video is essential for a clean content-level comparison.
4. **Weekday is context, not destiny.** Friday leads the mean, Sunday the median, and the distributions overlap. Scheduling should be paired with category, creator, and campaign context rather than optimized in isolation.
5. **Trend entry is usually fast, but resurfacing creates a long tail.** Median category velocity is typically one to two days, so medians are safer than means for launch expectations.

## Interpretation Boundaries

- Pearson correlation is linear association, not causation.
- The dataset contains only videos that reached the US trending list; it is not a random sample of all YouTube uploads.
- `views`, likes, dislikes, and comments are snapshots at the first observed trending appearance, not lifetime totals.
- Category averages can be unstable when category sample sizes are small.
- Disabled ratings/comments can mechanically lower observed interaction metrics.
