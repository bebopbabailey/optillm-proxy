#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
PATCH_FILE="${REPO_ROOT}/patches/optillm.patch"

if [[ ! -f "${PATCH_FILE}" ]]; then
  echo "Missing patch file: ${PATCH_FILE}" >&2
  exit 1
fi

PYTHON="${REPO_ROOT}/.venv/bin/python"
if [[ ! -x "${PYTHON}" ]]; then
  PYTHON="python3"
fi

"${PYTHON}" - <<'PY'
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.find_spec("optillm")
if spec is None or spec.origin is None:
    print("optillm is not installed. Run 'uv sync' first.", file=sys.stderr)
    sys.exit(1)
pkg_dir = Path(spec.origin).parent
print(str(pkg_dir))
PY

OPTILLM_DIR="$("${PYTHON}" - <<'PY'
import importlib.util
from pathlib import Path
spec = importlib.util.find_spec("optillm")
pkg_dir = Path(spec.origin).parent
print(str(pkg_dir))
PY
)"

SITE_PACKAGES_DIR="$(dirname "${OPTILLM_DIR}")"
cd "${SITE_PACKAGES_DIR}"
patch -p1 --forward --batch < "${PATCH_FILE}" || true
rm -f optillm/bon.py.rej optillm/server.py.rej
echo "Applied patch (or already present) in ${SITE_PACKAGES_DIR}"
