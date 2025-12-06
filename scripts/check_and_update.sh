#!/opt/homebrew/bin/bash
set -euo pipefail # exit on error, undefined var, and pipe failure

# Resolve symlinks to the script directory
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CACHE_FILE="$PROJECT_ROOT/cache/last_updated_ip.txt"
LOG_FILE="$PROJECT_ROOT/dns.log"

exec > >(tee -a "$LOG_FILE") 2>&1

source "$SCRIPT_DIR/.env"
source "$SCRIPT_DIR/get_records.sh"
source "$SCRIPT_DIR/helpers.sh"

# check if env vars are set
require_env ZONE_ID API_TOKEN BASE_URL

main() {
  log INFO " ==== Starting DNS Check/Update ==== "

  current_ip=$(get_public_ip) || exit 1
  cached_ip=$(cat "$CACHE_FILE" 2>/dev/null || echo "")

  if [[ "$current_ip" == "$cached_ip" ]]; then
    log INFO "No change in IP address"
    log INFO " ============== DONE =============== "
    exit 0
  fi

  log INFO "Cached IP Addr updated from: $cached_ip --> $current_ip"
  echo "$current_ip" >"$CACHE_FILE"

  update_all_records "$current_ip"

  log INFO " ============== DONE =============== "
}

update_all_records() {
  local cur_ip="$1"
  load_records

  for name in "${!records[@]}"; do
    update_single_record "$name" "${records[$name]}" "$cur_ip"
  done
}

update_single_record() {
  local name="$1"
  local dns_id="$2"
  local ip="$3"

  if get_resp=$(get_dns_record "$dns_id"); then
    req_ip=$(parse_response "$get_resp" '.result.content')
  else
    log ERROR "✗ Failed to get $name"
    log_response "$get_resp"
    exit 1
  fi

  if [[ "$req_ip" != "$ip" ]]; then
    if response=$(update_dns_record "$dns_id" "$ip"); then
      log INFO "✓ Updated $name to $ip"
    else
      log ERROR "✗ Failed to update $name"
      log_response "$response"
    fi
  else
    log INFO "✓ $name is already up to date"
  fi
}

main "$@"
