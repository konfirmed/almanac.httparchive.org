#standardSQL
# Get summary of all lighthouse scores for a category for PWA pages (i.e. those with a service worker and a manifest file)
# Note scores, weightings, groups and descriptions may be off in mixed months when new versions of Lighthouse roles out

CREATE TEMPORARY FUNCTION getAudits(auditRefs STRING, audits STRING)
RETURNS ARRAY<STRUCT<id STRING, weight INT64, audit_group STRING, title STRING, description STRING, score INT64>> LANGUAGE js AS '''
var auditrefs = JSON.parse(auditRefs);
var audits = JSON.parse(audits);
var results = [];
for (auditref of auditrefs) {
  results.push({
    id: auditref.id,
    weight: auditref.weight,
    audit_group: auditref.group,
    description: audits[auditref.id].description,
    score: audits[auditref.id].score
  });
}
return results;
''';

SELECT
  audits.id AS id,
  COUNTIF(audits.score > 0) AS num_pages,
  COUNT(0) AS total,
  COUNTIF(audits.score IS NOT NULL) AS total_applicable,
  SAFE_DIVIDE(COUNTIF(audits.score > 0), COUNTIF(audits.score IS NOT NULL)) AS pct,
  APPROX_QUANTILES(audits.weight, 100)[OFFSET(50)] AS median_weight,
  MAX(audits.audit_group) AS audit_group,
  MAX(audits.description) AS description
FROM
  --`httparchive.lighthouse.2021_07_01_mobile`,
  `httparchive.sample_data.lighthouse_mobile_10k`,
  UNNEST(getAudits(JSON_EXTRACT(report, '$.categories.pwa.auditRefs'),JSON_EXTRACT(report, '$.audits'))) AS audits
  JSON_EXTRACT(payload, '$._pwa') != "[]" AND
  JSON_EXTRACT(payload, '$._pwa.serviceWorkers') != "[]" AND
  JSON_EXTRACT(payload, '$._pwa.manifests') != "[]" AND
  LENGTH(report) < 20000000  # necessary to avoid out of memory issues. Excludes a handful of very large results
GROUP BY
  audits.id
ORDER BY
  median_weight DESC,
  id
