#standardSQL
# Manifests that are not JSON parsable for service worker pages
# Question: Below only uses first manifest - what should we do it more than one is defined?

CREATE TEMP FUNCTION canParseManifest(manifest STRING)
RETURNS BOOLEAN LANGUAGE js AS '''
try {
  manifestJSON = Object.values(JSON.parse(manifest))[0];
  if (typeof manifestJSON === 'string' && manifestJSON.trim() != '') {
    return false;
  }
  if (typeof manifestJSON === 'string' && manifestJSON.trim() === '') {
    return null;
  }
  return true;
} catch {
  return false;
}
''';

SELECT
  _TABLE_SUFFIX AS client,
  canParseManifest(JSON_EXTRACT(payload, '$._pwa.manifests')) AS can_parse,
  COUNT(0) AS freq,
  SUM(COUNT(0)) OVER (PARTITION BY _TABLE_SUFFIX) AS total,
  COUNT(0)/SUM(COUNT(0)) OVER (PARTITION BY _TABLE_SUFFIX) AS pct
FROM
  `httparchive.sample_data.pages_*`
  --`httparchive.pages.2021_07_01_*`
WHERE
  JSON_EXTRACT(payload, '$._pwa') != "[]" AND
  JSON_EXTRACT(payload, '$._pwa.manifests') != "[]" AND
  JSON_EXTRACT(payload, '$._pwa.serviceWorkers') != "[]"
GROUP BY
  client,
  can_parse
ORDER BY
  freq/total DESC,
  can_parse,
  client