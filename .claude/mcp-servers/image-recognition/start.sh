#!/usr/bin/env bash
set -euo pipefail

if [ -z "${MIMO_API_KEY:-}" ]; then
  echo "错误: 请先在用户环境变量中设置 MIMO_API_KEY" >&2
  exit 1
fi

python "$(dirname "$0")/server.py"
