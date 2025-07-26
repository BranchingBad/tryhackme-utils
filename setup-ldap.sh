#!/bin/bash

# This script automates the basic setup of OpenLDAP (slapd) based on the provided terminal output.
# It assumes an Ubuntu 20.04 (Focal Fossa) environment.

# --- Functions ---

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# --- Main Script ---

log_info "Starting OpenLDAP setup script..."

# 1. Update package lists and install slapd and ldap-utils
log_info "Updating package lists and installing slapd and ldap-utils..."
sudo apt-get update || log_error "Failed to update package lists."
sudo apt-get -y install slapd ldap-utils || log_error "Failed to install slapd and ldap-utils."
sudo systemctl enable slapd || log_error "Failed to enable slapd service."

# 2. Reconfigure slapd (initial setup)
log_info "Reconfiguring slapd for initial setup..."
# During this step, you will be prompted to set the admin password and other details.
# This script cannot automate those interactive prompts.
# You will need to manually enter the desired settings.
sudo dpkg-reconfigure -p low slapd

# 3. Create the olcSaslSecProps.ldif file
log_info "Creating olcSaslSecProps.ldif file..."
cat <<EOF > olcSaslSecProps.ldif
dn: cn=config
changetype: modify
replace: olcSaslSecProps
olcSaslSecProps: noanonymous,minssf=0
EOF

if [ ! -f "olcSaslSecProps.ldif" ]; then
    log_error "Failed to create olcSaslSecProps.ldif. Aborting."
fi

# 4. Apply the olcSaslSecProps.ldif configuration
log_info "Applying olcSaslSecProps.ldif configuration..."
sudo ldapmodify -Y EXTERNAL -H ldapi:// -f ./olcSaslSecProps.ldif || log_error "Failed to apply olcSaslSecProps.ldif."

# 5. Restart slapd service
log_info "Restarting slapd service..."
sudo service slapd restart || log_error "Failed to restart slapd service."

# 6. Verify SASL mechanisms
log_info "Verifying supported SASL mechanisms..."
ldapsearch -H ldap:// -x -LLL -s base -b "" supportedSASLMechanisms

# 7. Reconfigure slapd again (this might not be strictly necessary unless you want to change settings again)
# The terminal output shows this was run twice. It's included for fidelity but might be redundant.
log_info "Re-running dpkg-reconfigure slapd (if needed for further changes)..."
# Again, this will prompt for interactive input.
sudo dpkg-reconfigure -p low slapd

# 8. Re-apply olcSaslSecProps.ldif and restart (if dpkg-reconfigure overwrites it, which it shouldn't for olcSaslSecProps)
# The terminal output shows this was run twice. Included for fidelity.
log_info "Re-applying olcSaslSecProps.ldif and restarting slapd (if needed)..."
sudo ldapmodify -Y EXTERNAL -H ldapi:// -f ./olcSaslSecProps.ldif || log_error "Failed to re-apply olcSaslSecProps.ldif."
sudo service slapd restart || log_error "Failed to restart slapd service after re-applying config."

log_info "Re-verifying supported SASL mechanisms..."
ldapsearch -H ldap:// -x -LLL -s base -b "" supportedSASLMechanisms

log_info "OpenLDAP basic setup script finished. Please remember to manually configure passwords and other details when prompted by dpkg-reconfigure."