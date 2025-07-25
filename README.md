# TryHackMe Utilities 🛠️

## 🚀 Overview

Welcome to TryHackMe Utilities, a collection of handy scripts and tools designed to streamline and enhance your TryHackMe learning experience. Whether you're a beginner just starting your cybersecurity journey or an experienced hacker looking to optimize your workflow, these utilities aim to make your time on TryHackMe more efficient and enjoyable.

This repository provides various scripts to automate common tasks, fetch useful information, and generally simplify interactions with the TryHackMe platform.

## ✨ set-dns Features

DNS Resolver Configuration and Test Script
This script automates the process of adding a specific nameserver (10.200.80.101) to your dnsmasq configuration file (/etc/resolv-dnsmasq), ensures the nameserver is reachable, restarts the dnsmasq service, and then verifies if a specific Fully Qualified Domain Name (FQDN), thmdc.za.tryhackme.com, can be resolved using the newly configured DNS.

💡Important Notes:

dnsmasq Configuration: This script assumes that dnsmasq is configured to read its upstream nameservers from /etc/resolv-dnsmasq. If your dnsmasq setup uses a different file or method, you may need to adjust the RESOLV_FILE variable or the script's logic.

Systemd-resolved: The script comments out a line for restarting systemd-resolved. If systemd-resolved is managing your DNS and forwarding queries to dnsmasq, you might need to uncomment and use that line instead, or restart both.

IP Address and FQDN: You can modify the THMDCIP and THM_FQDN variables at the top of the script to suit your specific network and testing requirements.

Permissions: Ensure your user has sudo privileges to run this script successfully.

## 📄 License

Distributed under the GPL-3.0 license See LICENSE for more information.