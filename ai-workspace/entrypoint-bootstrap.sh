#!/bin/sh
set -eu

entrypoint_ref="${AI_WORKSPACE_ENTRYPOINT_REF:-main}"
case "$entrypoint_ref" in
  *[!A-Za-z0-9._/-]* | '')
    echo "AI_WORKSPACE_ENTRYPOINT_REF contains unsupported characters" >&2
    exit 1
    ;;
esac

entrypoint_dir="/workspace/.opencode"
entrypoint_path="$entrypoint_dir/entrypoint.sh"
entrypoint_url="https://raw.githubusercontent.com/SwaDeshiTech/prodhub-ai-workspace/${entrypoint_ref}/ai-workspace/entrypoint.sh"

mkdir -p "$entrypoint_dir"
node - "$entrypoint_url" "$entrypoint_path" <<'NODE'
const fs = require("node:fs/promises")
const [url, output] = process.argv.slice(2)

fetch(url)
  .then(async response => {
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    await fs.writeFile(output, await response.text(), { mode: 0o755 })
  })
  .catch(error => {
    console.error(`Unable to download AI workspace entrypoint from ${url}: ${error.message}`)
    process.exit(1)
  })
NODE

chmod 0755 "$entrypoint_path"
exec "$entrypoint_path" "$@"
