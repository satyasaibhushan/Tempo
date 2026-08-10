#!/bin/zsh

set -euo pipefail

repo_root="$SRCROOT/../.."
config_url="${CONVEX_URL:-}"

if [[ -z "$config_url" || "$config_url" == '$('* ]]; then
  env_file="$repo_root/.env.local"

  if [[ -f "$env_file" ]]; then
    while IFS='=' read -r key value; do
      if [[ "$key" == "CONVEX_URL" ]]; then
        config_url="$value"
        break
      fi
    done < "$env_file"
  fi
fi

config_url="${config_url#\"}"
config_url="${config_url%\"}"
config_url="${config_url#\'}"
config_url="${config_url%\'}"

if [[ "$config_url" != https://*.convex.cloud ]]; then
  echo "error: Set CONVEX_URL to an HTTPS convex.cloud deployment or add it to $repo_root/.env.local" >&2
  exit 1
fi

app_info="$TARGET_BUILD_DIR/$INFOPLIST_PATH"

if [[ ! -f "$app_info" ]]; then
  echo "error: Built app Info.plist is missing at $app_info" >&2
  exit 1
fi

/usr/libexec/PlistBuddy -c "Set :ConvexURL $config_url" "$app_info"

embedded_url="$(/usr/libexec/PlistBuddy -c 'Print :ConvexURL' "$app_info")"

if [[ "$embedded_url" != "$config_url" ]]; then
  echo "error: Failed to embed CONVEX_URL in $app_info" >&2
  exit 1
fi
