#standardSQL
# Percentiles of lighthouse pwa score
# This metric comes from Lighthouse only and is only available in mobile in HTTP Archive dataset
SELECT
  '2021_07_01' AS date,
  percentile,
  APPROX_QUANTILES(score, 1000)[OFFSET(percentile * 10)] AS score
FROM (
  SELECT
     CAST(JSON_EXTRACT(report, '$.categories.pwa.score') AS NUMERIC) AS score
  FROM
     `httparchive.lighthouse.2021_07_01_mobile`),
  UNNEST([10, 25, 50, 75, 90]) AS percentile
GROUP BY
  date,
  percentile
ORDER BY
  date,
  percentile