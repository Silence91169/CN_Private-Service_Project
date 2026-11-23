#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$REPO_ROOT" || exit 1

TIMEOUT_SECONDS=${DEMO_TIMEOUT_SECONDS:-20}
SAMPLE_COUNT=${DEMO_SAMPLE_COUNT:-10}
CAPTURE=0
CAPTURE_DIR=
RUN_OPTION=
LIST_ONLY=0
NO_COLOR=0
CONFIG_SOURCE="not configured"

usage() {
    cat <<'EOF'
Usage: bash scripts/demo.sh [options]

Options:
  --run NUMBER|all      Run one menu option non-interactively.
  --capture             Save genuine output under evidence/live-demo/session-TIMESTAMP/.
  --capture-dir DIR     Save output in a specific directory (implies --capture).
  --list                Print the menu and exit without network tests.
  --no-color            Disable terminal colours.
  --help                Show this help.

Optional overrides:
  DEMO_PRIMARY_DNS_IP, DEMO_SECONDARY_DNS_IP, DEMO_PRIMARY_EDGE_IP,
  DEMO_STANDBY_EDGE_IP, DEMO_BACKEND_A_IP, DEMO_BACKEND_B_IP,
  DEMO_HTTPS_PORT, DEMO_CA_FILE, DEMO_TIMEOUT_SECONDS, DEMO_SAMPLE_COUNT.

The launcher is read-only: it does not modify DNS, PF, interfaces, certificate
trust, nginx, dnsmasq, or backend processes.
EOF
}

while (($#)); do
    case "$1" in
        --run)
            (($# >= 2)) || { printf 'ERROR: --run requires a value\n' >&2; exit 2; }
            RUN_OPTION=$2
            shift 2
            ;;
        --capture)
            CAPTURE=1
            shift
            ;;
        --capture-dir)
            (($# >= 2)) || { printf 'ERROR: --capture-dir requires a directory\n' >&2; exit 2; }
            CAPTURE=1
            CAPTURE_DIR=$2
            shift 2
            ;;
        --list)
            LIST_ONLY=1
            shift
            ;;
        --no-color)
            NO_COLOR=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ -t 1 && $NO_COLOR -eq 0 ]]; then
    GREEN=$'\033[32m'
    RED=$'\033[31m'
    YELLOW=$'\033[33m'
    BLUE=$'\033[34m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'
else
    GREEN= RED= YELLOW= BLUE= BOLD= RESET=
fi

if [[ -f config/inventory.env ]]; then
    # The repository validator rejects shell metacharacters before inventory use.
    if grep -Ev '^[A-Z0-9_]+=[A-Za-z0-9_./:-]+$|^[[:space:]]*(#.*)?$' config/inventory.env | grep -q .; then
        printf '%sFAIL%s inventory contains an invalid line; refusing to source it.\n' "$RED" "$RESET" >&2
        exit 1
    fi
    # shellcheck disable=SC1091
    source config/inventory.env
    CONFIG_SOURCE="config/inventory.env"
fi

PRIMARY_DNS_IP=${DEMO_PRIMARY_DNS_IP:-${PRIMARY_DNS_IP:-}}
SECONDARY_DNS_IP=${DEMO_SECONDARY_DNS_IP:-${SECONDARY_DNS_IP:-}}
PRIMARY_EDGE_IP=${DEMO_PRIMARY_EDGE_IP:-${PRIMARY_EDGE_IP:-}}
STANDBY_EDGE_IP=${DEMO_STANDBY_EDGE_IP:-${STANDBY_EDGE_IP:-}}
BACKEND_A_IP=${DEMO_BACKEND_A_IP:-${BACKEND_A_IP:-}}
BACKEND_B_IP=${DEMO_BACKEND_B_IP:-${BACKEND_B_IP:-}}
BACKEND_A_PORT=${DEMO_BACKEND_A_PORT:-${BACKEND_A_PORT:-3001}}
BACKEND_B_PORT=${DEMO_BACKEND_B_PORT:-${BACKEND_B_PORT:-3002}}
HTTPS_PORT=${DEMO_HTTPS_PORT:-${PRIMARY_EDGE_HTTPS_PORT:-8443}}
CA_FILE=${DEMO_CA_FILE:-}
if [[ $CONFIG_SOURCE == "not configured" ]] && [[ -n ${DEMO_PRIMARY_DNS_IP:-}${DEMO_SECONDARY_DNS_IP:-}${DEMO_PRIMARY_EDGE_IP:-}${DEMO_STANDBY_EDGE_IP:-}${DEMO_BACKEND_A_IP:-}${DEMO_BACKEND_B_IP:-} ]]; then
    CONFIG_SOURCE="DEMO_* environment variables"
fi

if [[ $CAPTURE -eq 1 ]]; then
    if [[ -z $CAPTURE_DIR ]]; then
        CAPTURE_DIR="evidence/live-demo/session-$(date '+%Y%m%d-%H%M%S')"
    fi
    mkdir -p "$CAPTURE_DIR"
    CAPTURE_DIR=$(cd "$CAPTURE_DIR" && pwd)
    LOG_FILE="$CAPTURE_DIR/demo.log"
    {
        printf 'PRIVATE NETWORK SERVICE — LIVE DEMO EVIDENCE\n'
        printf 'Started: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
        printf 'Git commit: %s\n' "$(git rev-parse HEAD 2>/dev/null || printf unknown)"
        printf 'Configuration source: %s\n' "$CONFIG_SOURCE"
        printf 'Review this file for sensitive information before committing.\n\n'
    } > "$LOG_FILE"
    CAPTURE_PIPE="$CAPTURE_DIR/.demo-output.pipe"
    mkfifo "$CAPTURE_PIPE"
    tee -a "$LOG_FILE" < "$CAPTURE_PIPE" &
    TEE_PID=$!
    trap 'rm -f "$CAPTURE_PIPE"' EXIT
    exec > "$CAPTURE_PIPE" 2>&1
fi

banner() {
    printf '%s\n' '========================================='
    printf '  %sPRIVATE NETWORK SERVICE — LIVE DEMO%s\n' "$BOLD" "$RESET"
    printf '%s\n' '========================================='
}

menu() {
    banner
    cat <<'EOF'

1. Verify both DNS servers
2. Demonstrate nginx load balancing
3. Verify HTTPS / TLS
4. Demonstrate nginx caching
5. Verify standby nginx
6. Check all four network machines
7. Run static and local tests
8. Run complete non-destructive demo
9. Show GitHub and project information
0. Exit
EOF
}

section() {
    printf '\n%s[%s] %s%s\n' "$BLUE" "$(date '+%H:%M:%S')" "$1" "$RESET"
    if [[ $CAPTURE -eq 1 ]]; then printf 'Evidence test: %s\n' "$1"; fi
}

pass() { printf '%sPASS%s: %s\n' "$GREEN" "$RESET" "$*"; }
fail() { printf '%sFAIL%s: %s\n' "$RED" "$RESET" "$*" >&2; }
warn() { printf '%sWARN%s: %s\n' "$YELLOW" "$RESET" "$*"; }

run_timed() {
    local seconds=$1
    shift
    "$@" &
    local command_pid=$!
    (
        sleep "$seconds"
        if kill -0 "$command_pid" 2>/dev/null; then
            pkill -TERM -P "$command_pid" 2>/dev/null || true
            kill -TERM "$command_pid" 2>/dev/null || true
        fi
    ) &
    local timer_pid=$!
    wait "$command_pid"
    local status=$?
    kill "$timer_pid" 2>/dev/null || true
    wait "$timer_pid" 2>/dev/null || true
    if [[ $status -eq 143 ]]; then
        fail "command timed out after ${seconds}s: $*"
        return 124
    fi
    return "$status"
}

configuration_summary() {
    printf 'Configuration source: %s\n' "$CONFIG_SOURCE"
    printf 'Primary DNS:   %s\n' "${PRIMARY_DNS_IP:-NOT SET}"
    printf 'Secondary DNS: %s\n' "${SECONDARY_DNS_IP:-NOT SET}"
    printf 'Primary edge:  %s:%s\n' "${PRIMARY_EDGE_IP:-NOT SET}" "$HTTPS_PORT"
    printf 'Standby edge:  %s:%s\n' "${STANDBY_EDGE_IP:-NOT SET}" "$HTTPS_PORT"
    printf 'Backend A:     %s:%s\n' "${BACKEND_A_IP:-NOT SET}" "$BACKEND_A_PORT"
    printf 'Backend B:     %s:%s\n' "${BACKEND_B_IP:-NOT SET}" "$BACKEND_B_PORT"
    if ! network_config_ready; then
        warn 'Network inventory is incomplete. Copy config/inventory.example.env to config/inventory.env and enter current IPs.'
    fi
}

valid_ipv4() {
    local ip=$1 part
    local -a parts
    [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
    IFS=. read -r -a parts <<<"$ip"
    for part in "${parts[@]}"; do ((part >= 0 && part <= 255)) || return 1; done
}

network_config_ready() {
    local value
    for value in "$PRIMARY_DNS_IP" "$SECONDARY_DNS_IP" "$PRIMARY_EDGE_IP" "$STANDBY_EDGE_IP" "$BACKEND_A_IP" "$BACKEND_B_IP"; do
        [[ -n $value && $value != CHANGE_ME ]] && valid_ipv4 "$value" || return 1
    done
}

require_network_config() {
    if network_config_ready; then return 0; fi
    fail 'network inventory is missing or invalid; no network test was started'
    printf 'Create config/inventory.env from config/inventory.example.env, or set the documented DEMO_* overrides.\n' >&2
    return 1
}

run_dns() {
    require_network_config || return 1
    section 'DNS redundancy — direct queries to both resolvers'
    printf 'Both resolvers should currently return the primary edge. This does not claim automatic edge failover.\n'
    local failures=0
    run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-dns.sh "$PRIMARY_DNS_IP" "$PRIMARY_EDGE_IP" || failures=$((failures + 1))
    run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-dns.sh "$SECONDARY_DNS_IP" "$PRIMARY_EDGE_IP" || failures=$((failures + 1))
    if [[ $failures -eq 0 ]]; then pass 'both DNS servers returned the expected primary edge'; else fail "$failures DNS verification(s) failed"; fi
    return "$failures"
}

run_load_balancing() {
    require_network_config || return 1
    section 'nginx load balancing — uncached /healthz samples'
    printf 'The goal is to observe both healthy backends; strict A/B alternation is not guaranteed.\n'
    local temp_file
    temp_file=$(mktemp)
    if run_timed "$((TIMEOUT_SECONDS + SAMPLE_COUNT * 3))" bash scripts/verify/check-failover.sh "$PRIMARY_EDGE_IP" "$HTTPS_PORT" "$SAMPLE_COUNT" "$CA_FILE" | tee "$temp_file"; then
        if grep -q 'X-Backend: A' "$temp_file" && grep -q 'X-Backend: B' "$temp_file"; then
            pass 'uncached samples reached both Backend A and Backend B'
            rm -f "$temp_file"
            return 0
        fi
        fail 'requests succeeded, but this sample did not prove both backends'
    else
        fail 'one or more load-balancing requests failed'
    fi
    rm -f "$temp_file"
    return 1
}

run_tls() {
    require_network_config || return 1
    section 'Trusted TLS and HTTPS through the primary edge'
    printf 'Certificate verification remains enabled; curl -k is never used.\n'
    local failures=0
    if [[ -n $CA_FILE ]]; then
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-tls.sh "$PRIMARY_EDGE_IP" "$HTTPS_PORT" "$CA_FILE" || failures=$((failures + 1))
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-http.sh "$PRIMARY_EDGE_IP" "$HTTPS_PORT" "$CA_FILE" || failures=$((failures + 1))
    else
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-tls.sh "$PRIMARY_EDGE_IP" "$HTTPS_PORT" || failures=$((failures + 1))
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-http.sh "$PRIMARY_EDGE_IP" "$HTTPS_PORT" || failures=$((failures + 1))
    fi
    if [[ $failures -eq 0 ]]; then pass 'primary TLS identity and HTTPS health verified'; else fail "$failures TLS/HTTPS verification(s) failed"; fi
    return "$failures"
}

cache_request() {
    local label=$1
    local output_file=$2
    local -a curl_args=(--silent --show-error --max-time "$TIMEOUT_SECONDS" --resolve "app.team1.test:${HTTPS_PORT}:${PRIMARY_EDGE_IP}" --dump-header - --output /dev/null)
    if [[ -n $CA_FILE ]]; then curl_args+=(--cacert "$CA_FILE"); fi
    printf '%s\n' "$label"
    curl "${curl_args[@]}" "https://app.team1.test:${HTTPS_PORT}/api/status" | tee "$output_file"
}

run_cache() {
    require_network_config || return 1
    section 'nginx cache — exact HTTPS /api/status'
    printf 'A safe wait lets the existing ten-second entry expire; no cache files are deleted.\n'
    local first second
    first=$(mktemp)
    second=$(mktemp)
    printf 'Waiting 11 seconds for the configured cache validity window...\n'
    sleep 11
    if ! run_timed "$TIMEOUT_SECONDS" cache_request 'Request 1 after expiry window:' "$first"; then
        fail 'first cache request failed'; rm -f "$first" "$second"; return 1
    fi
    if ! run_timed "$TIMEOUT_SECONDS" cache_request 'Immediate request 2:' "$second"; then
        fail 'second cache request failed'; rm -f "$first" "$second"; return 1
    fi
    local first_state second_state
    first_state=$(awk 'BEGIN{IGNORECASE=1} /^X-Cache-Status:/ {gsub("\r", "", $2); print toupper($2); exit}' "$first")
    second_state=$(awk 'BEGIN{IGNORECASE=1} /^X-Cache-Status:/ {gsub("\r", "", $2); print toupper($2); exit}' "$second")
    rm -f "$first" "$second"
    if [[ $second_state == HIT && ( $first_state == MISS || $first_state == EXPIRED || $first_state == STALE ) ]]; then
        pass "cache transition observed: ${first_state} -> ${second_state}"
        return 0
    fi
    fail "expected MISS/EXPIRED/STALE then HIT; observed '${first_state:-missing}' then '${second_state:-missing}'"
    return 1
}

run_standby() {
    require_network_config || return 1
    section 'Standby nginx — direct verification without DNS cutover'
    printf 'This verifies standby accessibility only; DNS cutover remains manual.\n'
    local failures=0
    if [[ -n $CA_FILE ]]; then
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-tls.sh "$STANDBY_EDGE_IP" "$HTTPS_PORT" "$CA_FILE" || failures=$((failures + 1))
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-http.sh "$STANDBY_EDGE_IP" "$HTTPS_PORT" "$CA_FILE" || failures=$((failures + 1))
    else
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-tls.sh "$STANDBY_EDGE_IP" "$HTTPS_PORT" || failures=$((failures + 1))
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-http.sh "$STANDBY_EDGE_IP" "$HTTPS_PORT" || failures=$((failures + 1))
    fi
    if [[ $failures -eq 0 ]]; then pass 'standby TLS and HTTPS verified directly'; else fail "$failures standby verification(s) failed"; fi
    return "$failures"
}

direct_backend() {
    local name=$1 ip=$2 port=$3 expected=$4
    local response
    response=$(curl --silent --show-error --fail --max-time "$TIMEOUT_SECONDS" "http://${ip}:${port}/healthz") || return 1
    printf '%s: %s\n' "$name" "$response"
    grep -q "\"backend\":\"$expected\"" <<<"$response"
}

run_all_machines() {
    require_network_config || return 1
    section 'Four-Mac reachability and service health'
    local failures=0
    run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-dns.sh "$PRIMARY_DNS_IP" "$PRIMARY_EDGE_IP" || failures=$((failures + 1))
    run_timed "$TIMEOUT_SECONDS" direct_backend 'Backend A / Shivam' "$BACKEND_A_IP" "$BACKEND_A_PORT" A || failures=$((failures + 1))
    run_timed "$TIMEOUT_SECONDS" direct_backend 'Backend B / Yash' "$BACKEND_B_IP" "$BACKEND_B_PORT" B || failures=$((failures + 1))
    if [[ -n $CA_FILE ]]; then
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-http.sh "$PRIMARY_EDGE_IP" "$HTTPS_PORT" "$CA_FILE" || failures=$((failures + 1))
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-http.sh "$STANDBY_EDGE_IP" "$HTTPS_PORT" "$CA_FILE" || failures=$((failures + 1))
    else
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-http.sh "$PRIMARY_EDGE_IP" "$HTTPS_PORT" || failures=$((failures + 1))
        run_timed "$TIMEOUT_SECONDS" bash scripts/verify/check-http.sh "$STANDBY_EDGE_IP" "$HTTPS_PORT" || failures=$((failures + 1))
    fi
    if [[ $failures -eq 0 ]]; then pass 'all four machines and their assigned services responded'; else fail "$failures machine/service check(s) failed; verify IP inventory and running services"; fi
    return "$failures"
}

run_static() {
    section 'Repository static and local tests'
    if run_timed 90 bash scripts/run-static-tests.sh; then pass 'static and local repository tests passed'; return 0; fi
    fail 'static/local repository tests failed'
    return 1
}

show_project() {
    section 'GitHub and project information'
    git remote -v
    printf 'Branch: %s\n' "$(git branch --show-current)"
    printf 'Commit: %s\n' "$(git rev-parse HEAD)"
    git log -1 --format='Author: %an <%ae>%nSubject: %s%nDate: %ad' --date=iso
    printf 'GitHub: https://github.com/Silence91169/CN_Private-Service_Project\n'
    configuration_summary
    pass 'project information displayed'
}

run_complete() {
    section 'Complete non-destructive demonstration'
    configuration_summary
    local failures=0
    run_dns || failures=$((failures + 1))
    run_all_machines || failures=$((failures + 1))
    run_load_balancing || failures=$((failures + 1))
    run_tls || failures=$((failures + 1))
    run_cache || failures=$((failures + 1))
    run_standby || failures=$((failures + 1))
    run_static || failures=$((failures + 1))
    if [[ $failures -eq 0 ]]; then pass 'complete non-destructive demo passed'; else fail "$failures demo section(s) failed"; fi
    return "$failures"
}

run_choice() {
    case "$1" in
        1) run_dns ;;
        2) run_load_balancing ;;
        3) run_tls ;;
        4) run_cache ;;
        5) run_standby ;;
        6) run_all_machines ;;
        7) run_static ;;
        8|all) run_complete ;;
        9) show_project ;;
        0) printf 'Exiting without changing network state.\n'; return 0 ;;
        *) fail "invalid menu option: $1"; return 2 ;;
    esac
}

if [[ $LIST_ONLY -eq 1 ]]; then
    menu
    exit 0
fi

banner
configuration_summary
if [[ $CAPTURE -eq 1 ]]; then
    warn "Capturing genuine output to $LOG_FILE; review it before any commit."
fi

if [[ -n $RUN_OPTION ]]; then
    run_choice "$RUN_OPTION"
    exit $?
fi

while true; do
    menu
    printf '\nSelect an option: '
    if ! IFS= read -r choice; then
        printf '\nInput closed; exiting safely.\n'
        exit 0
    fi
    run_choice "$choice" || true
    [[ $choice == 0 ]] && exit 0
    printf '\nPress Enter to return to the menu...'
    IFS= read -r _ || exit 0
done
