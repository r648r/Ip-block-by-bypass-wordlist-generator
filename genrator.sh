#!/bin/bash

print_usage() {
    echo "Usage: generate_ips [OPTIONS]"
    echo "Options:"
    echo "    -n, --network    Specify the network and subnet mask in CIDR format."
    echo "    -o, --output     Specify the output filename where the result will be saved."
    echo "    -s, --source     Specify the template text file in which the word 'payload' will be replaced by the IP address."
    echo "    -h, --help       Display this help message."
}

validate_input() {
    if [[ -z "$network_with_mask" ]]; then
        echo "Error: Network not specified."
        exit 1
    fi

    if [[ -z "$output" ]]; then
        echo "Error: Output filename not specified."
        exit 1
    fi

    if [[ -z "$source" ]]; then
        echo "Error: Source text file not specified."
        exit 1
    fi
}

generate_ips() {
    local network_with_mask=""
    local output=""
    local source=""
    local help=""

    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -n|--network)
            network_with_mask="$2"
            shift
            shift
            ;;
            -o|--output)
            output="$2"
            shift
            shift
            ;;
            -s|--source)
            source="$2"
            shift
            shift
            ;;
            -h|--help)
            help="true"
            shift
            ;;
            *)
            echo "Unknown option: $1"
            exit 1
            ;;
        esac
    done

    if [[ ! -z "$help" ]]; then
        print_usage
        exit 0
    fi

    validate_input

    network=$(echo "$network_with_mask" | cut -d '/' -f1)
    netmask=$(echo "$network_with_mask" | cut -d '/' -f2)
    num_addresses=$((2 ** (32 - netmask)))

    IFS='.' read -r octet1 octet2 octet3 octet4 <<< "$network"
    network_decimal=$((octet1 * 256**3 + octet2 * 256**2 + octet3 * 256 + octet4)) "$output"
    for ((i=0; i<num_addresses; i++)); do
        generate_single_ip "$network_decimal" "$i" "$output" "$source"
    done
}

generate_single_ip() {
    local network_decimal="$1"
    local i="$2"
    local output="$3"
    local source="$4"

    ip_decimal=$((network_decimal + i))
    ip=$(printf "%d.%d.%d.%d\n" $((ip_decimal / 256**3 % 256)) $((ip_decimal / 256**2 % 256)) $((ip_decimal / 256 % 256)) $((ip_decimal % 256)))

    echo "" >> "$output"
    echo "$ip"
    sed "s/payload/$ip/g" "$source" >> "$output"
}

generate_ips "$@"
