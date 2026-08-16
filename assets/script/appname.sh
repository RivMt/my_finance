#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MODE="${1:-production}"

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [production|edge|dev|demo]" >&2
  exit 2
fi

case "${MODE}" in
  production)
    APP_NAME="MyFinance"
    SHORT_NAME="MyFinance"
    APP_ID="myfinance.release"
    ;;
  edge)
    APP_NAME="MyFinance (Edge)"
    SHORT_NAME="MF Edge"
    APP_ID="myfinance.edge"
    ;;
  dev)
    APP_NAME="MyFinance (Dev)"
    SHORT_NAME="MF Dev"
    APP_ID="myfinance.dev"
    ;;
  demo)
    APP_NAME="MyFinance (Demo)"
    SHORT_NAME="MF Demo"
    APP_ID="myfinance.demo"
    ;;
  *)
    echo "Unknown mode '${MODE}'. Use production, edge, dev, or demo." >&2
    exit 2
    ;;
esac

if [[ -x "${PROJECT_ROOT}/.venv/Scripts/python.exe" ]]; then
  PYTHON="${PROJECT_ROOT}/.venv/Scripts/python.exe"
elif [[ -x "${PROJECT_ROOT}/.venv/bin/python" ]]; then
  PYTHON="${PROJECT_ROOT}/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON="python"
else
  echo "Python 3 is required." >&2
  exit 1
fi

"${PYTHON}" - \
  "${PROJECT_ROOT}/web/manifest.json" \
  "${PROJECT_ROOT}/web/index.html" \
  "${APP_NAME}" "${SHORT_NAME}" "${APP_ID}" <<'PY'
import json
import re
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
index_path = Path(sys.argv[2])
app_name, short_name, app_id = sys.argv[3:6]

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["name"] = app_name
manifest["short_name"] = short_name
manifest["id"] = app_id
manifest_path.write_text(json.dumps(manifest, indent=4) + "\n", encoding="utf-8")

html = index_path.read_text(encoding="utf-8")
html, mobile_title_count = re.subn(
    r'(<meta\s+name="apple-mobile-web-app-title"\s+content=")[^"]*(">)',
    lambda match: f"{match.group(1)}{short_name}{match.group(2)}",
    html,
    count=1,
)
html, title_count = re.subn(
    r"(<title>)[^<]*(</title>)",
    lambda match: f"{match.group(1)}{app_name}{match.group(2)}",
    html,
    count=1,
)
if mobile_title_count != 1 or title_count != 1:
    raise SystemExit("Could not find the expected app title elements in web/index.html")
index_path.write_text(html, encoding="utf-8")
PY

echo "Configured app name for ${MODE}: ${APP_NAME} (${APP_ID})"
