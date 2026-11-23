#!/bin/sh

set -eu

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

info() {
    printf 'INFO: %s\n' "$*"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

load_inventory() {
    inventory_file=${1:-config/inventory.env}
    [ -f "$inventory_file" ] || die "inventory not found: $inventory_file (copy config/inventory.example.env first)"

    # Inventory files are trusted local operator input. Reject shell metacharacters
    # before sourcing so an accidental command cannot be executed.
    if grep -Ev '^[A-Z0-9_]+=[A-Za-z0-9_./:-]+$|^[[:space:]]*(#.*)?$' "$inventory_file" | grep -q .; then
        die "inventory contains an invalid line or unsupported character"
    fi

    # shellcheck disable=SC1090
    . "$inventory_file"
}

require_value() {
    variable_name=$1
    eval "variable_value=\${$variable_name-}"
    [ -n "$variable_value" ] || die "$variable_name is not set"
    [ "$variable_value" != CHANGE_ME ] || die "$variable_name still equals CHANGE_ME"
}

validate_ipv4() {
    ip=$1
    printf '%s\n' "$ip" | awk -F. '
        NF != 4 { exit 1 }
        {
            for (i = 1; i <= 4; i++) {
                if ($i !~ /^[0-9]+$/ || $i < 0 || $i > 255) exit 1
            }
        }
    ' || die "invalid IPv4 address: $ip"
}

validate_port() {
    port=$1
    case "$port" in
        ''|*[!0-9]*) die "invalid port: $port" ;;
    esac
    [ "$port" -ge 1 ] && [ "$port" -le 65535 ] || die "port out of range: $port"
}

validate_ttl() {
    ttl=$1
    case "$ttl" in
        ''|*[!0-9]*) die "invalid TTL: $ttl" ;;
    esac
    [ "$ttl" -ge 1 ] && [ "$ttl" -le 86400 ] || die "TTL must be between 1 and 86400 seconds"
}

validate_interface() {
    interface=$1
    printf '%s\n' "$interface" | grep -Eq '^[A-Za-z0-9]+$' || die "invalid interface name: $interface"
}

validate_inventory() {
    for variable_name in PRIMARY_DNS_IP SECONDARY_DNS_IP PRIMARY_EDGE_IP STANDBY_EDGE_IP BACKEND_A_IP BACKEND_B_IP; do
        require_value "$variable_name"
        eval "variable_value=\${$variable_name}"
        validate_ipv4 "$variable_value"
    done

    for variable_name in BACKEND_A_PORT BACKEND_B_PORT PRIMARY_EDGE_HTTP_PORT PRIMARY_EDGE_HTTPS_PORT STANDBY_EDGE_HTTP_PORT STANDBY_EDGE_HTTPS_PORT; do
        require_value "$variable_name"
        eval "variable_value=\${$variable_name}"
        validate_port "$variable_value"
    done

    require_value DNS_TTL
    validate_ttl "$DNS_TTL"
    require_value BACKEND_A_INTERFACE
    require_value BACKEND_B_INTERFACE
    validate_interface "$BACKEND_A_INTERFACE"
    validate_interface "$BACKEND_B_INTERFACE"
    require_value TLS_CERT_PATH
    require_value TLS_KEY_PATH
    require_value HOMEBREW_PREFIX
    case "$HOMEBREW_PREFIX" in /*) : ;; *) die "HOMEBREW_PREFIX must be an absolute path" ;; esac
}

replace_token() {
    file=$1
    token=$2
    value=$3
    escaped_value=$(printf '%s' "$value" | sed 's/[&|]/\\&/g')
    sed -i.bak "s|__${token}__|$escaped_value|g" "$file"
    rm -f "$file.bak"
}
