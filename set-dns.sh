#!/bin/bash

THMDCIP="10.200.80.101"
RESOLV_FILE="/etc/resolv-dnsmasq"

# Check if the nameserver already exists to prevent duplicate entries
if ! grep -q "nameserver $THMDCIP" "$RESOLV_FILE"; then
    # Use double quotes for variable expansion in sed, and escape the dot in the IP
    # '1i' inserts before the first line. 'nameserver ...\n' adds a newline.
    sudo sed -i "1inameserver $THMDCIP" "$RESOLV_FILE"
    echo "Added nameserver $THMDCIP to $RESOLV_FILE"
else
    echo "Nameserver $THMDCIP already present in $RESOLV_FILE. No changes made."
fi

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
echo "Current content of $RESOLV_FILE:"
cat "$RESOLV_FILE"