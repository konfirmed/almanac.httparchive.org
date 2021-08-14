# standardSQL
# HTTP/2 % 1st Party versus 3rd Party by Type
SELECT
  percentile,
  client,
  is_third_party,
  type,
  ROUND(APPROX_QUANTILES(http2_3_pct, 1000)[OFFSET(percentile * 10)], 2) AS http2_3_pct
FROM (
  SELECT
    client,
    page,
    is_third_party,
    type,
    COUNTIF(http_version IN ('HTTP/2', 'HTTP/3', 'QUIC', 'h3-29', 'h3-Q050')) / COUNT(0) AS http2_3_pct
  FROM (
    SELECT
      client,
      page,
      url,
      type,
      respSize,
      protocol AS http_version,
      NET.HOST(url) IN (SELECT domain FROM `httparchive.almanac.third_parties` WHERE date = '2021-07-01') AS is_third_party
    FROM
      `httparchive.almanac.requests`
    WHERE
      date = '2021-07-01')
  GROUP BY
    client,
    page,
    is_third_party,
    type),
  UNNEST([5, 10, 20, 30, 40, 50, 60, 70, 90, 95, 100])
GROUP BY
  percentile,
  client,
  is_third_party,
  type
ORDER BY
  percentile,
  client,
  is_third_party,
  type
