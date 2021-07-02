# https://stackoverflow.com/questions/65048929/bigquery-extract-keys-from-json-object-convert-json-from-object-to-key-value-a
CREATE TEMP FUNCTION jsonToKeyValueArray(input STRING)
RETURNS Array<Struct<key String, value ARRAY<String>>>
LANGUAGE js AS """
  let json = JSON.parse(input);
  return Object.keys(json).map(e => {
    return { "key" : e, "value" : json[e] }
  });
""";

WITH pages_events AS (
  SELECT
    _TABLE_SUFFIX AS client,
    url,
    JSON_VALUE(payload, "$._events") AS metrics
  FROM
    `httparchive.pages.2021_08_01_*`
)
, sites_and_events AS ( 
  SELECT 
    client,
    site, -- the home page that was crawled
    url_and_events.key as url, -- the url that added the event listener, can be scripts etc.
    event -- the name of the event
  FROM 
    (SELECT client, url as site, jsonToKeyValueArray(events) events_per_site from pages_events), 
    UNNEST(events_per_site) url_and_events, 
    UNNEST(url_and_events.value) event
)

SELECT 
  client,
  event,
  COUNT(DISTINCT site) nb_websites,
  COUNT(DISTINCT url) nb_urls,
FROM
  sites_and_events
WHERE
  -- device* events, from https://www.esat.kuleuven.be/cosic/publications/article-3078.pdf
  event LIKE 'device%'
GROUP BY 
  1, 2