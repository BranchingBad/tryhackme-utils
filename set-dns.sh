#!/bin/bash

THMDCIP="10.200.80.101"
RESOLV_FILE="/etc/resolv-dnsmasq"
THM_FQDN="thmdc.za.tryhackme.com" # FQDN to test resolution

# Check if the nameserver already exists to prevent duplicate entries
if ! grep -q "nameserver $THMDCIP" "$RESOLV_FILE"; then
    # Use double quotes for variable expansion in sed, and escape the dot in the IP
    # '1i' inserts before the first line. 'nameserver ...\n' adds a newline.
    sudo sed -i "1inameserver $THMDCIP" "$RESOLV_FILE"
    echo "Added nameserver $THMDCIP to $RESOLV_FILE"
else
    echo "Nameserver $THMDCIP already present in $RESOLV_FILE. No changes made."
fi

echo ""
echo "Current content of $RESOLV_FILE:"
cat "$RESOLV_FILE"

echo ""
echo "Pinging $THMDCIP to ensure reachability..."
# Ping with a count of 3 and a timeout of 1 second per packet
if ping -c 3 -W 1 "$THMDCIP" > /dev/null; then
    echo "$THMDCIP is reachable."

    # The service to restart depends on which service consumes /etc/resolv-dnsmasq.
    # If dnsmasq is using it, restart dnsmasq.
    # If systemd-resolved is managing it, then systemd-resolved might be right,
    # but often systemd-resolved creates /etc/resolv.conf and dnsmasq uses it.
    # Assuming dnsmasq is directly configured to use resolv-dnsmasq:
    echo "Restarting dnsmasq service..."
    sudo systemctl restart dnsmasq

    # If you are absolutely sure systemd-resolved is the consumer:
    # echo "Restarting systemd-resolved service..."
    # sudo systemctl restart systemd-resolved

    echo ""
    echo "Checking DNS resolution for $THM_FQDN using $THMDCIP..."

    # Perform nslookup using the newly configured nameserver (if dnsmasq uses it)
    # We specifically ask nslookup to use the THMDCIP as the server for the query
    # This ensures we are testing the configuration directly.
    if nslookup "$THM_FQDN" "$THMDCIP" > /dev/null 2>&1; then
        echo "Successfully resolved $THM_FQDN via $THMDCIP."
    else
        echo "Failed to resolve $THM_FQDN via $THMDCIP. DNS configuration might not be effective or FQDN does not exist."
    fi
else
    echo "Error: $THMDCIP is not reachable. Cannot proceed with DNS configuration and testing."
    exit 1 # Exit with an error code
fi