#!/usr/bin/env bash
set -euo pipefail

name="${1:-init}"

if ! command -v migrate >/dev/null 2>&1; then
  echo "Error: 'migrate' command not found in PATH." >&2
  exit 1
fi

migrate create -ext sql -dir db/migrations -seq "$name"
