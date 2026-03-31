#!/bin/bash
# 디버그 실행 스크립트 (API 키 자동 주입)
# 사용법: bash scripts/run_debug.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env 파일이 없습니다. ROOT_DIR=$ROOT_DIR"
  exit 1
fi

source "$ENV_FILE"

flutter run \
  --dart-define=MARKTGURU_CLIENT_KEY="$MARKTGURU_CLIENT_KEY" \
  --dart-define=MARKTGURU_API_KEY="$MARKTGURU_API_KEY" \
  "$@"
