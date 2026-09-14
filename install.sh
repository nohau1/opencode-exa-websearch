#!/usr/bin/env bash
# Install the exa-websearch custom tool into the opencode config.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
TOOLS="$CONFIG/tools"
SCRIPTS="$CONFIG/scripts"
ENV_FILE="$CONFIG/exa-search.env"

for bin in curl jq bash; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "error: '$bin' is required but not found in PATH" >&2
    exit 1
  }
done

mkdir -p "$TOOLS" "$SCRIPTS"

install -m 644 "$ROOT/tools/websearch.ts" "$TOOLS/websearch.ts"
install -m 700 "$ROOT/scripts/exa-search.sh" "$SCRIPTS/exa-search.sh"

if [ -f "$ENV_FILE" ]; then
  echo "keeping existing $ENV_FILE"
else
  install -m 600 "$ROOT/.env.example" "$ENV_FILE"
  echo "created $ENV_FILE - set EXA_API_KEY (and EXA_PROXY if needed)"
fi

echo
echo "Installed:"
echo "  $TOOLS/websearch.ts"
echo "  $SCRIPTS/exa-search.sh"
echo "  $ENV_FILE"
echo
echo "Restart opencode for the tool to appear."
