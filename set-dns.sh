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

    echo "Attempting to restart dnsmasq service..."
    # Try to restart dnsmasq service
    sudo systemctl restart dnsmasq

    # Check dnsmasq service status after the restart attempt
    DNSMASQ_STATUS=$(systemctl status dnsmasq.service 2>&1)

    # Check if dnsmasq failed and if the reason is "Address already in use"
    if echo "$DNSMASQ_STATUS" | grep -q "failed to create listening socket for port 53: Address already in use"; then
        echo "Detected 'Address already in use' error for dnsmasq. Attempting to fix by disabling systemd-resolved DNSStubListener."

        # Backup resolved.conf before modifying
        if [ ! -f "/etc/systemd/resolved.conf.bak" ]; then
            sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak
            echo "Backed up /etc/systemd/resolved.conf to /etc/systemd/resolved.conf.bak"
        fi

        # Modify /etc/systemd/resolved.conf to disable DNSStubListener
        # Use sed to uncomment/set DNSStubListener=no
        sudo sed -i '/^#\?DNSStubListener=yes/cDNSStubListener=no' /etc/systemd/resolved.conf
        echo "Set DNSStubListener=no in /etc/systemd/resolved.conf"

        # Restart systemd-resolved to apply changes
        echo "Restarting systemd-resolved service..."
        sudo systemctl restart systemd-resolved
        echo "systemd-resolved restarted. Port 53 should now be free for dnsmasq."

        # Try restarting dnsmasq again
        echo "Attempting to restart dnsmasq service again..."
        sudo systemctl restart dnsmasq
        
        # Re-check dnsmasq status after the fix attempt
        DNSMASQ_STATUS=$(systemctl status dnsmasq.service 2>&1)
        if echo "$DNSMASQ_STATUS" | grep -q "Active: active (running)"; then
            echo "dnsmasq service is now active and running."
        else
            echo "Warning: dnsmasq service is still not running after fix attempt. Manual intervention may be required."
            echo "See 'systemctl status dnsmasq.service' and 'journalctl -xe' for details."
        fi
    elif echo "$DNSMASQ_STATUS" | grep -q "Active: active (running)"; then
        echo "dnsmasq service is active and running."
    else
        echo "Warning: dnsmasq service failed to restart for an unknown reason."
        echo "See 'systemctl status dnsmasq.service' and 'journalctl -xe' for details."
    fi

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