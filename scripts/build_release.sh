#!/bin/bash
# AngebotsFuchs 릴리즈 빌드 스크립트
# 사용법: bash scripts/build_release.sh

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env 파일이 없습니다: $ENV_FILE"
  echo "   .env 파일을 생성하고 API 키를 입력해주세요."
  exit 1
fi

# .env 파일에서 키 읽기
export $(grep -v '^#' "$ENV_FILE" | xargs)

if [ -z "$MARKTGURU_CLIENT_KEY" ] || [ -z "$MARKTGURU_API_KEY" ]; then
  echo "❌ .env 파일에 MARKTGURU_CLIENT_KEY 또는 MARKTGURU_API_KEY가 없습니다."
  exit 1
fi

echo "▶ 릴리즈 AAB 빌드 시작..."

flutter build appbundle --release \
  --dart-define=MARKTGURU_CLIENT_KEY="$MARKTGURU_CLIENT_KEY" \
  --dart-define=MARKTGURU_API_KEY="$MARKTGURU_API_KEY"

echo ""
echo "✅ 빌드 완료!"
echo "   파일 위치: build/app/outputs/bundle/release/app-release.aab"