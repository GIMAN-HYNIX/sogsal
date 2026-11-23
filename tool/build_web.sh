#!/usr/bin/env bash
# 폰 웹앱 빌드. 사용: tool/build_web.sh [base-href]  (기본 /sogsal/)
set -euo pipefail
cd "$(dirname "$0")/.."
BASE="${1:-/sogsal/}"
flutter build web --release --no-web-resources-cdn --base-href "$BASE"
python3 tool/make_sw.py build/web
