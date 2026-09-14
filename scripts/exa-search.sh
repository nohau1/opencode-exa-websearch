#!/usr/bin/env bash
# Exa web search, proxy-aware. Prints the raw JSON response from api.exa.ai/search.
#
# Usage: exa-search.sh "query" [numResults]
#
# Credentials are read from (first match wins):
#   1. $EXA_SEARCH_ENV (path to an env file)
#   2. ~/.config/opencode/exa-search.env
#   3. the current environment
set -euo pipefail

ENV_FILE="${EXA_SEARCH_ENV:-$HOME/.config/opencode/exa-search.env}"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

: "${EXA_API_KEY:?Set EXA_API_KEY in $ENV_FILE (see .env.example)}"

QUERY="${1:?Usage: exa-search.sh \"query\" [numResults]}"
NUM="${2:-8}"

BODY="$(jq -n --arg q "$QUERY" --argjson n "$NUM" \
  '{query: $q, numResults: $n, contents: {highlights: true, text: false}}')"

ARGS=(
  -sS --max-time 60
  -X POST 'https://api.exa.ai/search'
  -H "x-api-key: $EXA_API_KEY"
  -H 'Content-Type: application/json'
  -d "$BODY"
)

# Route through SOCKS5 when configured (works around Cloudflare blocking on
# mcp.exa.ai / api.exa.ai from some networks).
if [ -n "${EXA_PROXY:-}" ]; then
  ARGS+=(--socks5-hostname "$EXA_PROXY")
  if [ -n "${EXA_PROXY_USER:-}" ]; then
    ARGS+=(--proxy-user "$EXA_PROXY_USER")
  fi
fi

curl "${ARGS[@]}"
