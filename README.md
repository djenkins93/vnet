# vNet
A minimalist, stealth-focused airgap and network isolation utility for Linux.

VoidNet (vnet) is a lightweight shell-based utility designed to create a temporary or on-demand airgapped environment with advanced monitoring and forensic capabilities. It isolates the host from outbound network traffic while optionally logging any connection attempts or analyzing suspicious traffic. Ideal for pentesters, digital forensics professionals, and privacy enthusiasts.

# Features
    • Airgap Mode (simulate total network isolation)
    •  Blackhole Routing (reroute all outbound traffic to null)
    • DNS Flushing and Restoration
    •  Dynamic NIC Module Unloading/Reloading
    •  Auto-repair & Interface Recovery (even in unstable VM environments)
    • Advanced Traffic Monitoring (tcpdump + ngrep for password/token leaks)
    • Real-time Outbound Traffic Viewer (formatted for readability)
    • Works on Linux based systems, VirtualBox, Xen, and bare metal machines
    • Extremely fast deployment and rollback with CLI flags

# Usage
Run Interactively:  sudo ./vnet
Run via CLI flags: 
	sudo vnet --on           # Activate airgap
	sudo vnet --off          # Deactivate airgap
	sudo vnet --monitor      # Monitor outbound kernel traffic
	sudo vnet --forensics-on # Start tcpdump + ngrep session
	sudo vnet --forensics-off# Stop forensic capture
	sudo vnet --status       # Show NIC, IPs, DNS, and routing
	sudo vnet --repair       # Attempt forced connectivity restore

# Requirements
	Bash/sh compatible shell
    • Linux with iproute2, iptables, tcpdump, ngrep
    • Root privileges (required for network control)
    • Recommended: Void Linux (musl) or other minimal distributions

# Installation
	git clone https://github.com/yourname/voidnet
	cd voidnet
	chmod +x vnet
	sudo ln -s "$PWD/vnet" /usr/local/bin/vnet

# Compatibility
VoidNet works reliably on:
    • VirtualBox, QEMU/KVM, Xen-based VMs
    •  x86_64 bare metal laptops/desktops
Tested on Void Linux (musl), Alpine, and Debian-based systems.

# Security Philosophy
VoidNet uses blackhole routing and NIC module unloading to simulate a true airgap. It attempts no external calls and provides fully local logging and control. It favors simplicity, reversibility, and auditability over bloated dependencies.


# License
MIT License © 2025 Dietrich Jenkins

# Disclaimer
VoidNet is intended for educational and security research purposes only. Do not use it to disrupt networks you do not own or operate.

# Contributions
Pull requests, issue reports, and improvements welcome.
