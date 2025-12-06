#!/opt/homebrew/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

load_records() {
  source "$SCRIPT_DIR/.env"
  source "$SCRIPT_DIR/helpers.sh"

  declare -gA records

  # Convert comma separated string to array
  IFS=',' read -ra wanted <<<"$TRACKED_RECORDS"

  while IFS='|' read -r name id; do
    for w in "${wanted[@]}"; do
      if [[ "$name" == "$w" ]]; then
        records["$name"]="$id"
        break
      fi
    done
  done < <(
    api_get "/zones/$ZONE_ID/dns_records" | jq -r '.result[] | "\(.name)|\(.id)"'
  )
}

# Only run if executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  load_records
  echo "Found ${#records[@]} records"
  echo "----------------------------"
  for name in "${!records[@]}"; do
    echo "$name --> ${records[$name]}"
  done
fi
