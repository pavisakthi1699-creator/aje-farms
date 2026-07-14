#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$APP_ROOT/.." && pwd)"

cd "$APP_ROOT"

echo "== Flutter analyze =="
flutter analyze

echo "== Flutter tests =="
flutter test test/

echo "== Golden drift check =="
flutter test test/visual_regression_test.dart

echo "== Diff hygiene =="
cd "$REPO_ROOT"
git diff --check

if [[ -f package.json ]]; then
  echo "== Server contract tests =="
  npm run test:server
fi

echo "Frontend quality gate passed."
