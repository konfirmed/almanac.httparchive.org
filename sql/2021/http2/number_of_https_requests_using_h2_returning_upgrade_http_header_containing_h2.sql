# standardSQL
# Number of HTTPS requests using HTTP/2 which return upgrade HTTP header containing h2
CREATE TEMPORARY FUNCTION getUpgradeHeader(payload STRING)
RETURNS STRING
LANGUAGE js AS """
  try {
    var $ = JSON.parse(payload);
    var headers = $.response.headers;
    var st = headers.find(function(e) {
      return e['name'].toLowerCase() === 'upgrade'
    });
    return st['value'];
  } catch (e) {
    return '';
  }
""";

SELECT
  client,
  firstHtml,
  protocol AS http_version,
  COUNTIF(getUpgradeHeader(payload) LIKE "%h2%") AS num_requests,
  COUNT(0) AS total
FROM
  `httparchive.almanac.requests`
WHERE
  date = '2021-07-01' AND
  url LIKE "https://%" AND
  protocol = "HTTP/2"
GROUP BY
  client,
  firstHtml,
  http_version
