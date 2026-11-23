#!/bin/sh

set -eu
repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$repo_root"
. scripts/lib/common.sh

inventory_file=${1:-config/inventory.env}
output_dir=${2:-generated}
load_inventory "$inventory_file"
validate_inventory

mkdir -p "$output_dir/dns/primary" "$output_dir/dns/secondary" "$output_dir/nginx" "$output_dir/firewall"

render() {
    source_file=$1
    destination_file=$2
    cp "$source_file" "$destination_file"
    for variable_name in PRIMARY_DNS_IP SECONDARY_DNS_IP PRIMARY_EDGE_IP STANDBY_EDGE_IP BACKEND_A_IP BACKEND_B_IP BACKEND_A_PORT BACKEND_B_PORT PRIMARY_EDGE_HTTP_PORT PRIMARY_EDGE_HTTPS_PORT STANDBY_EDGE_HTTP_PORT STANDBY_EDGE_HTTPS_PORT DNS_TTL BACKEND_A_INTERFACE BACKEND_B_INTERFACE HOMEBREW_PREFIX TLS_CERT_PATH TLS_KEY_PATH; do
        eval "variable_value=\${$variable_name}"
        replace_token "$destination_file" "$variable_name" "$variable_value"
    done
    if grep -Eq '__[A-Z0-9_]+__' "$destination_file"; then
        die "unresolved placeholder in $destination_file"
    fi
}

render dns/primary/dnsmasq.conf.template "$output_dir/dns/primary/dnsmasq.conf"
render dns/secondary/dnsmasq.conf.template "$output_dir/dns/secondary/dnsmasq.conf"
render dns/records/primary-edge.hosts.template "$output_dir/dns/primary-edge.hosts"
render dns/records/standby-edge.hosts.template "$output_dir/dns/standby-edge.hosts"
render nginx/primary.conf.template "$output_dir/nginx/primary.conf"
render nginx/standby.conf.template "$output_dir/nginx/standby.conf"
render firewall/backend-a.pf.conf.template "$output_dir/firewall/backend-a.pf.conf"
render firewall/backend-b.pf.conf.template "$output_dir/firewall/backend-b.pf.conf"

info "rendered machine-specific files under $output_dir/"
info "generated files are ignored by Git; review them before deployment"
