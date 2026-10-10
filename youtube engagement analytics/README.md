# YouTube Trending — Reach ≠ Response

> **6,351 videos. One first-trending snapshot each.** The project separates audience scale from audience intensity instead of treating “viral” as a single metric.

## Signal Board

| Signal | First-Appearance Result |
|---|---:|
| Raw trending snapshots | 40,949 |
| Unique videos analyzed | **6,351** |
| `views ↔ likes` | **0.761** |
| `likes ↔ comments` | **0.806** |
| `views ↔ engagement_rate` | **0.057** |
| Top avg-view category | **Music · 1.39M** |
| Top avg-engagement category* | **Music · 8.23%** |
| Passive-reach videos | **335** |
| Niche-loyalty videos | **352** |

\*headline category comparisons use meaningful-volume categories; all categories remain available in the notebook.

## The Analytical Lens

```text
40,949 daily trending snapshots
              ↓
first appearance per video
              ↓
         6,351 videos
              ↓
  reach ─ response ─ velocity
    │         │          │
  views    engagement   days_to_trend
              ↓
category + weekday + audience archetypes
```

The JSON file is not a second fact table. It is the category dictionary that turns numeric YouTube IDs into readable labels before benchmarking.

## What Makes This More Than A Heatmap

The required analysis is completed, then extended where the data suggests a useful question:

- **Grain sensitivity:** how much repeated trending snapshots change correlation strength.
- **Audience archetypes:** high-reach / low-response videos versus low-reach / high-response videos.
- **Interactive exploration:** hover through individual titles in the reach-vs-engagement map.
- **Trend velocity:** median-to-75th-percentile windows instead of misleading long-tail means.
- **Metadata reality check:** tests whether simply adding more tags tracks performance.

## Visual Atlas

```text
visuals/
├── 01 correlation heatmap.png
├── 02 average views by category.png
├── 03 engagement rate by category.png
├── 04 views by publish weekday boxplot.png
├── 05 top 10 first appearance views.png
├── 06 grain sensitivity comparison.png
├── 07 reach vs engagement by category.png
├── 08 interactive reach vs engagement.html
└── 09 category trend velocity.png
```

The boxplot uses a log scale because view counts are highly skewed; the interactive scatter keeps 6,351 points inspectable without turning the static notebook into a label cloud.

## A Grain Decision That Changes The Answer

The task note quotes a strong `views ↔ likes` relationship near **0.84**. On all 40,949 repeated trending snapshots, this file produces **0.849**. After the required first-appearance deduplication, it becomes **0.761**.

That is not a discrepancy to hide — it is evidence that repeated observations can strengthen apparent relationships.

## Run The Notebook

Place `USvideos.csv` and `US_category_id.json` beside the notebook, or keep them in a nearby Downloads/Desktop folder. Then run:

```bash
pip install pandas numpy matplotlib seaborn plotly jupyter
```

Open **`youtube engagement analytics.ipynb`** and run top to bottom. The notebook recreates every PNG and the interactive HTML inside `visuals/`.

## Project Files

```text
youtube engagement analytics/
├── youtube engagement analytics.ipynb
├── README.md
├── note.md
└── visuals/
```

Raw Kaggle data is intentionally not bundled in the project folder.

## Data Source

Kaggle — *Trending YouTube Video Statistics* (`USvideos.csv` + `US_category_id.json`).
