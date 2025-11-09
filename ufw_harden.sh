#!/bin/bash

set -e

RULES_FILE="/etc/iptables/rules.v4"

enable_hardening() {
	echo "[+] Applying UFW base rules..."
	sudo ufw reset
	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	sudo ufw enable

	echo "[+] Adding iptables rules to block ping and scan types..."

	sudo iptables -A INPUT -p icmp --icmp-type echo-request -j DROP # Block ping
	sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP      # Null scan
	sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP       # XMAS scan
	sudo iptables -A INPUT -p tcp --tcp-flags ALL FIN -j DROP       # FIN scan
	sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP   # Invalid packets

	echo "[+] Saving iptables rules..."
	sudo apt-get install -y iptables-persistent
	sudo iptables-save | sudo tee "$RULES_FILE" >/dev/null

	echo "[✓] Hardening enabled."
}

disable_hardening() {
	echo "[!] Disabling UFW and clearing iptables..."

	sudo ufw disable
	sudo iptables -F
	sudo iptables -X

	if [ -f "$RULES_FILE" ]; then
		sudo rm "$RULES_FILE"
	fi

	echo "[+] You may need to reboot or reload iptables-persistent."
	echo "[✓] Hardening disabled."
}

case "$1" in
enable)
	enable_hardening
	;;
disable)
	disable_hardening
	;;
*)
	echo "Usage: $0 {enable|disable}"
	exit 1
	;;
esac
