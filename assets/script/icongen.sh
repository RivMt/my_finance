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
  production) SVG_NAME="icon.svg" ;;
  edge) SVG_NAME="icon-edge.svg" ;;
  dev) SVG_NAME="icon-dev.svg" ;;
  demo) SVG_NAME="icon-demo.svg" ;;
  *)
    echo "Unknown mode '${MODE}'. Use production, edge, dev, or demo." >&2
    exit 2
    ;;
esac

SOURCE_SVG="${PROJECT_ROOT}/assets/icon/${SVG_NAME}"
VENV_DIR="${PROJECT_ROOT}/.venv"
REQUIREMENTS="${SCRIPT_DIR}/requirements.txt"
GENERATOR="${SCRIPT_DIR}/generate_icon.py"

if [[ ! -f "${SOURCE_SVG}" ]]; then
  echo "SVG source not found: ${SOURCE_SVG}" >&2
  exit 1
fi

if [[ ! -d "${VENV_DIR}" ]]; then
  PYTHON_COMMAND=()
  if command -v py >/dev/null 2>&1 && py -3 -c "import sys" >/dev/null 2>&1; then
    PYTHON_COMMAND=(py -3)
  elif command -v python3 >/dev/null 2>&1; then
    PYTHON_COMMAND=(python3)
  elif [[ -d "/c/Program Files/Blender Foundation" ]]; then
    # Blender bundles standard CPython and is a useful fallback on Windows.
    BLENDER_PYTHON="$(find "/c/Program Files/Blender Foundation" -path '*/python/bin/python.exe' -print 2>/dev/null | sort -V | tail -n 1)"
    if [[ -n "${BLENDER_PYTHON}" ]]; then
      PYTHON_COMMAND=("${BLENDER_PYTHON}")
    fi
  elif command -v python >/dev/null 2>&1; then
    PYTHON_COMMAND=(python)
  fi

  if [[ ${#PYTHON_COMMAND[@]} -eq 0 ]]; then
    echo "Python 3 is required." >&2
    exit 1
  fi
  "${PYTHON_COMMAND[@]}" -m venv "${VENV_DIR}"
fi

if [[ -x "${VENV_DIR}/Scripts/python.exe" ]]; then
  VENV_PYTHON="${VENV_DIR}/Scripts/python.exe"
elif [[ -x "${VENV_DIR}/bin/python" ]]; then
  VENV_PYTHON="${VENV_DIR}/bin/python"
else
  echo "The virtual environment has no Python executable: ${VENV_DIR}" >&2
  exit 1
fi

"${VENV_PYTHON}" -m pip install --disable-pip-version-check -r "${REQUIREMENTS}"

echo "Generating ${MODE} icons from ${SVG_NAME}"
"${VENV_PYTHON}" "${GENERATOR}" "${SOURCE_SVG}" "${PROJECT_ROOT}/assets/icon/icon-desktop.png" 512 512
"${VENV_PYTHON}" "${GENERATOR}" "${SOURCE_SVG}" "${PROJECT_ROOT}/assets/icon/icon-full.png" 1024 1024

(
  cd "${PROJECT_ROOT}"
  dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
)

MASKABLE_ICON_SIZES=(192 512)
for size in "${MASKABLE_ICON_SIZES[@]}"; do
  # Keep the complete SVG box, including its padding, at 60% of the canvas.
  "${VENV_PYTHON}" "${GENERATOR}" \
    "${SOURCE_SVG}" "${PROJECT_ROOT}/web/icons/Icon-maskable-${size}.png" \
    "${size}" "${size}" --icon-size "$(( (size * 3 + 2) / 5 ))"
done

IOS_ICON_SIZES=(58 76 80 87 114 120 152 167 180)
for size in "${IOS_ICON_SIZES[@]}"; do
  "${VENV_PYTHON}" "${GENERATOR}" \
    "${SOURCE_SVG}" "${PROJECT_ROOT}/web/icons/Icon-${size}.png" "${size}" "${size}"
done

SPLASH_SIZES=(
  1125x2436 1136x640 1170x2532 1179x2556 1242x2208 1242x2688
  1284x2778 1290x2796 1334x750 1488x2266 1536x2048 1620x2160
  1640x2360 1668x2224 1668x2388 1668x2420 1792x828 2048x1536
  2048x2732 2064x2752 2160x1620 2208x1242 2224x1668 2266x1488
  2360x1640 2388x1668 2420x1668 2436x1125 2532x1170 2556x1179
  2688x1242 2732x2048 2752x2064 2778x1284 2796x1290 640x1136
  750x1334 828x1792
)

for dimensions in "${SPLASH_SIZES[@]}"; do
  width="${dimensions%x*}"
  height="${dimensions#*x}"
  if (( width > height )); then
    long_side="${width}"
  else
    long_side="${height}"
  fi
  # Raster sizes are integral, so round long_side / 5 to the nearest pixel.
  icon_size="$(( (long_side + 2) / 5 ))"
  "${VENV_PYTHON}" "${GENERATOR}" \
    "${SOURCE_SVG}" "${PROJECT_ROOT}/web/splashes/splash_${dimensions}.png" \
    "${width}" "${height}" --icon-size "${icon_size}" --background "#FFFFFF"
done

"${VENV_PYTHON}" "${GENERATOR}" \
  "${SOURCE_SVG}" "${PROJECT_ROOT}/web/splashes/icon.png" 512 512
cp "${SOURCE_SVG}" "${PROJECT_ROOT}/web/icons/Icon.svg"
"${VENV_PYTHON}" -c '
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
manifest = json.loads(path.read_text(encoding="utf-8"))
svg_icon = {
    "src": "icons/Icon.svg",
    "sizes": "any",
    "purpose": "any",
    "type": "image/svg+xml",
}
manifest["icons"] = [
    svg_icon,
    *(icon for icon in manifest.get("icons", []) if icon.get("src") != svg_icon["src"]),
]
path.write_text(json.dumps(manifest, indent=4) + "\n", encoding="utf-8")
' "${PROJECT_ROOT}/web/manifest.json"

echo "Icon generation complete (${MODE})."
