#!/usr/bin/env bash
# Fails if SonarQube reports any Security Hotspot still in TO_REVIEW status.
set -euo pipefail

: "${SONAR_HOST_URL:?SONAR_HOST_URL is required}"
: "${SONAR_PROJECT_KEY:?SONAR_PROJECT_KEY is required}"
: "${SONAR_TOKEN:?SONAR_TOKEN is required}"

URL="${SONAR_HOST_URL%/}/api/hotspots/search?projectKey=${SONAR_PROJECT_KEY}&status=TO_REVIEW&ps=1"

RESPONSE="$(curl -fsS -u "${SONAR_TOKEN}:" "${URL}")"
if command -v python3 >/dev/null 2>&1; then
  PY=python3
else
  PY=python
fi
TOTAL="$("${PY}" -c "import json,sys; print(json.loads(sys.argv[1])['paging']['total'])" "${RESPONSE}")"

if [[ "${TOTAL}" -gt 0 ]]; then
  echo "Gatekeeping failed: ${TOTAL} Security Hotspot(s) still in TO_REVIEW."
  exit 1
fi

echo "Security Hotspots gate passed (TO_REVIEW count: ${TOTAL})."
