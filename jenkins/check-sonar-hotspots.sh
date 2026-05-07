#!/usr/bin/env bash
# Fails if SonarQube reports any Security Hotspot still in TO_REVIEW status.
# Pure POSIX shell parsing — no python / jq dependency, so it runs on
# minimal Jenkins agent images (e.g. jenkins/jenkins:lts).
set -euo pipefail

: "${SONAR_HOST_URL:?SONAR_HOST_URL is required}"
: "${SONAR_PROJECT_KEY:?SONAR_PROJECT_KEY is required}"
: "${SONAR_TOKEN:?SONAR_TOKEN is required}"

URL="${SONAR_HOST_URL%/}/api/hotspots/search?projectKey=${SONAR_PROJECT_KEY}&status=TO_REVIEW&ps=1"

RESPONSE="$(curl -fsS -u "${SONAR_TOKEN}:" "${URL}")"

TOTAL="$(printf '%s' "${RESPONSE}" \
  | tr -d '\n' \
  | sed -n 's/.*"paging"[[:space:]]*:[[:space:]]*{[^}]*"total"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')"

if [[ -z "${TOTAL}" ]]; then
  echo "Could not parse hotspots response from SonarQube:"
  echo "${RESPONSE}"
  exit 2
fi

if [[ "${TOTAL}" -gt 0 ]]; then
  echo "Gatekeeping failed: ${TOTAL} Security Hotspot(s) still in TO_REVIEW."
  exit 1
fi

echo "Security Hotspots gate passed (TO_REVIEW count: ${TOTAL})."
