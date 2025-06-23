#!/bin/bash
# 
# Voidnet - A secure, fast, and minimalist tool to enforce an airgap by unloading network modules and blocking outbound traffic
#
#
#
echo "                                                           ,VdAL'                b#@@@}                                                                 "
echo "                                                           b@@@@}                !@@@@8                                                                  "
echo "                                                           ~bBQX_                ^@@@@$                                                                   "
echo "'p#@#M_       ]#@#b_   >48#@@@@@@@@@@#E7. x#@@@@@@@#QAi'     	    ,X8#@@@@@@@@@@@@@@|   .iAQ#@@@@@@@@Qp*     ,nO#@@@@@Bm;         =Q@@@@@@@@@@@@@@@@@@h"
echo " A@@@@bi     r@@@@$'  P@@@@@@@@@@@@@@@@@8,A@@@@@@@@@@@@Q=  5@@@@V  |#@@@@@@@@@@@@@@@#a   =Q@@@@@@@@@@@@@@@P  |#@@@@@@@@@@@V        i@@@@@@@@@@@@@@@@@@@B- "
echo " -8@@@@s    !#@@@Q,  |@@@@@AkkkkkkkaB@@@@U,nwwkkkw4B@@@@b  S@@@@V _#@@@@A4wkkkkkwe1r-    A@@@@BfkkkkkaB@@@@( ,#@@@@N4wh#@@@@^       i|kkkkkkkkkkkkkkkkwV! "
echo "  @Q@@@@X^?iB@@@@~   l@@@@4Axxxxxx~ i@@@@5'\''>>>^d@@@@R'  S@@@@V -@@@@'>>>>>>>>>>>>~i'  5@@@@V       n@@@@V ='@@@@@y^>^M@@@@U>>>~'          s' ,;'         "
echo "   -p@@@@@@@@@@4r    -N@@@@@@@@@@@@4!A@@@@@@@@@@@@@@@@@4^  S@@@@V  z@@@@@@@@@@@@@@@@@@Ri S@@@@V       n@@@@V  z@@@@@@@@@@@@@@@@@@4!        O@@@--'        "
echo "     @<q#@@@@@By,      xR#@@@@@@@@@Q_ iN@@@@@@@@@@@@@Qs;   k@@@#)   ^R#@@@@@@@@@@@@@@@p  w@@@#?       r@@@#)   ^S#@@@@@@@@@@@@@@@B;        @U@@@8,        "
echo "       I=>>;,I           i,~>>>>>>~I    iX3'xxxxxxx4'      xxXx     i,~xxxxxxxxxxxxx~i   @@@#l         _;~^    I_!>>>>>>>>>>>>~xx          I ,;^        "

#set -x
echo ""
echo -e "	 			\e[1m (VoidNet- Secure Stealth Airgap Utility with Advanced Monitoring )\e[0m"
#
#MODULES_FILE="/tmp/airlock_modules.txt"
log() { echo -e "[\033[1mVOIDNET\033[0m] $1"; }

# === Auto-detect active NIC modules ===
detect_nics() {
	NIC_MODULES=$(lsmod | awk '/(e1000|iwl|r8169|ath|realtek|usbnet|8139|broadcom|virtio)/ {print $1}' | sort -u | tr '\n' ' ')
	[ -z "$NIC_MODULES" ] && NIC_MODULES="e1000e iwlwifi r8169 virtio_net"
} 

# === DNS Managment ===
flush_dns() {
	[ -f /etc/resolv.conf ] && cp /etc/resolv.conf /etc/resolv.conf.bak
	[ -x /usr/bin/resolvectl ] && reslovectl flush-caches
	#echo > /etc/resolve.conf
	: > /etc/resolve.conf
	log "DNS flushed and resolvers disabled."
}


restore_dns() {
	[ -f /etc/resolv.conf.bak ] && mv /etc/resolv.conf.bak /etc/resolv.conf && log "DNS restored."
}


# === Routing Control === 
enable_blackhole() {
	ip route replace blackhole 0.0.0.0/0 2>/dev/null
	ip -6 route replac blackhole ::/0 2>/dev/null
	log "Blackhole routing activated."
}

disable_blackhole() {
	ip route del blackhole 0.0.0.0/0 2>/dev/null
	ip -6 route del blackhole ::/0 2>/dev/null
	log "Blackhole routing deactivated."
}


# === Module Control ===
unload_modules() { 
	for mod in $NIC_MODULES; do
		if [ -n "$mod" ]; then
			modprobe -r "$mod" 2>/dev/null && log "Unloaded: $mod"
		fi
	done
}

reload_modules() {
	for mod in $NIC_MODULES; do
		if [ -n "$mod" ]; then
			log "Reloading module: $mod"
			modinfo "$mod" >/dev/null 2>&1 && modprobe "$mod" 2>/dev/null && log "RELOADED: $mod"
		fi
	done
}

# === Rebind PCI NICs ===
rebind_nics() {
	for dev in /sys/class/net*; do
		iface=$(basename "$dev")
		[ "$iface" = "lo" ] && continue

		pci=$(readlink -f "$dev/device" | awk -F'/' '{print $NF}')
		driver_path="/sys/bus/pci/devices/$pci/driver"

		[ -e "$driver_path" ] || continue
		driver=$(basename "$(READLINK "driver_path")")

		echo "$pci" > "/sys/bus/pci/drivers/$driver/unbind"
		sleep 1
		echo "$pci" > "sys/bus/pci/drivers/$driver/bind"

		log "REBOUND $ifce"
	done
}

# === Manual PCI Rebind (Extra Recovery) ===
manual_pci_rebind() {
	NIC_PIC=$(lspci -nn | grep -i 'Ethernet' | awk '{print $1}' | head -n1)
	NIC_DRIVER=$(lspci -nnk | grep -A3 "$NIC_PCI" | grep "Kernel driver in use" | awk '{print $5}')
	PCI_PATH="/sys/bus/pci/devices/0000:$NIC_PCI"

	if [ -d "$PCI_PATH" ] && [ -n "$NIC_DRIVER" ]; then
		echo "0000:$NIC_PCI" > "/sys/bus/pci/devices/0000:$NCI_PCI/driver/driver/unbind"
		sleep 1
		echo "0000:$NCI_PCI" > "/sys/bus/pci/drivers/$NIC_DRIVER/bind"
		log "Manually rebound PCI NIC $NIC_PCI to $NIC_DRIVER"
	fi

	udevadm trigger --subsystem-match=net
	echo 1 > /sys/bus/pci/rescan
}

# === Force Repair ===
force_repair() { 
	detect_nics
	reload_modules
	manual_pci_rebind
	up_interfaces
	restore_dns

	udevadm settle

	iface=""
	for attempt in 1 2 3; do
		iface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n1)
		[ -n "$iface" ] && [ "$(cat /sys/class/net/$iface/operstate 2>/dev/null)" = "up" ] && break
		log "Waiting for NIC to appear (attempt $attempt)..."
		sleep 2
	done

	gateway="192.168.1.1"

	if [ -n "$iface" ]; then
		ip route add default via $gateway dev $iface 2>/dev/null || true
		log "Detected interface: $iface"
		dhcpcd -n "$iface" &>/dev/null
		#log "Route set via $iface to $gateway"
		echo -e "[\033[1;32mVOIDNET\033[0m] \033[1;32mRoute set via $iface to $gateway\033[0m"
	else
		log "No network interface found for routing."
	fi

	#log "Force repair attempted. Check interface, IP, and routing manually."

}
#
# === Interface Management ===
down_interfaces() {
	for iface in $(ls /sys/class/net/ | grep -v lo); do
		ip link set "$iface" down 2>/dev/null && log "Interface down: $iface"
	done
}

up_interfaces(){
	for iface in $(ls /sys/class/net/ | grep -v lo); do
		ip link set "$iface" up 2>/dev/null && log "Interface up: $iface"
	done

	sleep 2 # give the interface a moment

	if sv check dhcpcd >/dev/null 2>&1; then
		sv down dhcpcd 2 >/dev/null
		sleep 1
		sv up dhcpcd && log "DHCPCD restarted via runit."
	else
		pkill dhcpcd 2>/dev/null
		dhcpcd &>/dev/null &
		log "DHCPD started manually."
	fi

		log "DHCPCD RESTARTED>"
}


# === Blackhole Traffic Loggin" ===
log_blackhole() {
	mkdir -p /var/log/airlock
	tail -F /var/log/socklog/kernel/current 2>/dev/null \
		| grep --line-buffered "OUTBOUND:" >> /var/log/airlock/blocked.log &
	echo $! > /tmp/airlock_log.pid
	log "Blackhole logging enabled."
}


stop_log_blackhole() {
	[ -f /tmp/airlock_log.pid ] && kill $(cat /tmp/airlock.pid) 2>/dev/null && rm /tm/airlock_log.pid
	log "BLACKHOLE LOGGING STOPPED>"
}
#
# === Airlock Switch ===
voidnet_on() {
	detect_nics
	log "Activating voidnet..."
	flush_dns
	enable_blackhole
	down_interfaces
	unload_modules
	log_blackhole
	log "Airgap Activated."
}

voidnet_off() {
	log "Deactivating Airgap..."
	stop_log_blackhole
	reload_modules
	rebind_nics

	echo 1 > /sys/bus/pci/rescan	# force PCI rediscovery
	udevadm trigger --subsystem-match=net	# Trigger udev to rebind NICS 

	manual_pci_rebind
	disable_blackhole
	#command -v dhcpcd >/dev/null && pkill dhcpcd && dhcpcd &>/dev/null &
	up_interfaces
	restore_dns
	#log "Network restored."

	# Netowrk auto-check and repair if needed 
	if ! ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1; then
		#log "No connectivity detected after deactivation. Attempting automatic repair."
		echo -e "[\033[1;31mVOIDNET\033[0m] \033[1;31mNo connectivity detected after deactivation. Attempting automatic repair. \033[0m"
		force_repair
	fi

	if ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1; then
		log "Network conn. restored."
	fi

	log "Airgap Deactivated."
}


# == Status Check ===
status_check() {
	echo "\n=== VOIDNET STATUS ===="
	echo "\n-- INterfaces --"
	ip link show | grep -E '^[0-9]+: ' | grep -v LOOPBACK
	echo "\n-- IP Addresses --"
	ip addr show | grep -R 'inet '
	echo "\n-- Routing Table --"
	ip route
	echo "\n-- DNS --"
	cat /etc/resolv.conf
	echo "\n-- Loaded NIC MOdules --"
	lsmod | grep -Ei 'e1000|r8169|virtio|xen_netfront|iwl|usbnet'
}


# Monitor outbound traffic in real-time
monitor_traffic() { 
	log "Starting live outbound traffic monitoring"

	# Add temporary loggin rule if not already active
	if ! iptables -C OUTPUT -j LOG --log-prefix "OUTBOUND" --log-level 4 2>/dev/null; then
		iptables -A OUTPUT -j LOG --log-prefix "OUTBOUND" --log-level 4
	fi

	echo "Monitoring outbound traffic. Press Ctrl+C to stop."
	#tail -F /var/log/socklog/kernel/current | grep --line-buffered "OUTBOUND:"
	tail -F /var/log/socklog/kernel/current | grep --line-buffered "OUTBOUND" | awk '
	BEGIN {
		printf "%-20s %-15s %-15s %-6s %-6s %-5s %-5s %-s\n", "Timestamp", "Source IP", "Destination IP", "SPort", "DPort", "Proto", "Len", "Info";
		print "------------------------------------------------------------------------------------------";
	}
	{ 
		match($0, /SRC=([0-9.]+)/, src);
		match($0, /DST=([0-9.]+)/, dst);
		match($0, /SPT=([0-9]+)/, sport);
		match($0, /DPT=([0-9]+)/, dport);
		match($0, /PROTO=([A-Z]+)/, proto);
		match($0, /LEN=([0-9]+)/, len);
		timestamp = substr($0, 0, 15);
		printf "%-20s %-15s %-15s %-6s %-6s %-5s %-5s %-s\n", timestamp, src[1], dst[1], sport[1], dport[1], proto[1], len[1], info;
	}'

}


# Interactive menu
main_menu() {
	echo ""
	echo ""
	while true; do 
		echo "-------------------- Voidnet Menu --------------------"
		echo "1. Open Voidnet (simulate airgap) 󰛴"
		echo "2. Close Voidnet (restore network) 󰱓"
		echo "3. Monitor outbound traffic 󰈈"
		echo "4. EXIT"
		echo "------------------------------------------------------"
		read -rp "Select an option [1-4]: " choice 

		case "$choice" in 
			1) voidnet_on ;;
			2) voidnet_off ;;
			3) monitor_traffic ;;
			4) log "Exiting Voidnet."; exit 0;;
			*) echo "Invalid option, please try again." ;;
		esac
		echo ""
	done
}

# === Root Required ===
 [ "$(id -u)" -ne 0 ] && log "Must run as root." && exit 1
main_menu
