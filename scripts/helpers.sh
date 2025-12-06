#!/opt/homebrew/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.env"

auth_header="Authorization: Bearer $API_TOKEN"
CURL_TIMEOUT=10
CURL_RETRIES=3

log() {
  local level="$1"
  shift
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
}

log_response() {
  local response="$1"
  local errors=$(echo "$response" | jq -r '.errors[].message // empty')
  local messages=$(echo "$response" | jq -r '.messages[].message // empty')

  if [[ -n "$errors" ]]; then
    while IFS= read -r e; do log ERROR "$e"; done <<<"$errors"
  fi

  if [[ -n "$messages" ]]; then
    while IFS= read -r m; do log INFO "$m"; done <<<"$messages"
  fi
}

get_public_ip() {
  local ip
  ip=$(curl -s --max-time "$CURL_TIMEOUT" https://api.ipify.org)
  if [[ -z "$ip" ]]; then
    log ERROR "Could not get public IP"
    exit 1
  fi
  echo "$ip"
}

parse_response() {
  local resp="$1"
  local field="$2"
  echo "$resp" | jq -r "$field // empty"
}

api_get() {
  local endpoint="$1"
  curl -s --max-time "$CURL_TIMEOUT" --retry "$CURL_RETRIES" \
    "$BASE_URL$endpoint" \
    -H "$auth_header" \
    -H "Content-Type: application/json"
}

api_patch() {
  local endpoint="$1"
  local data="$2"
  curl -s --max-time "$CURL_TIMEOUT" --retry "$CURL_RETRIES" \
    -X PATCH "$BASE_URL$endpoint" \
    -H "$auth_header" \
    -H "Content-Type: application/json" \
    -d "$data"
}

check_success() {
  local resp="$1"
  local success=$(parse_response "$resp" '.success')
  if [[ "$success" != "true" ]]; then
    return 1
  fi
  return 0
}

update_dns_record() {
  local record_id="$1"
  local ip="$2"
  local resp
  resp=$(api_patch "/zones/$ZONE_ID/dns_records/$record_id" '{"content": "'"$ip"'"}')
  echo "$resp"
  check_success "$resp"
}

get_dns_record() {
  local record_id="$1"
  local resp
  resp=$(api_get "/zones/$ZONE_ID/dns_records/$record_id")
  echo "$resp"
  check_success "$resp"
}

require_env() {
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      log ERROR "Missing env var: $var"
      exit 1
    fi
  done
}
