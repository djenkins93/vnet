# vNet (VoidNet)
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
	sudo ./vnet		  # run in interactive tui 
	sudo vnet --on            # Activate airgap + blackhole routing  
	sudo vnet --off           # Deactivate airgap and blackhole route
	sudo vnet --monitor       # Monitor outbound kernel traffic
	sudo vnet --forensics-on  # Start tcpdump + ngrep session
	sudo vnet --forensics-off # Stop forensic capture
	sudo vnet --status        # Show NIC, IPs, DNS, and routing
	sudo vnet --repair        # Attempt forced connectivity restore
 # Scenarios
 ## 1. Safe Malware & Suspicious Binary Analysis
Create a controlled, airgapped sandbox to execute potentially malicious software.  
`vnet` ensures no outbound network traffic escapes while optionally logging or blackholing connection attempts — ideal for reversing C2 behavior or identifying hidden telemetry.

- **Perfect for:** Malware analysts, threat researchers, security labs  
- **Benefit:** Prevents data leaks while revealing stealthy network behavior

---

## 2. Penetration Testing in Airgapped or Zero-Trust Conditions
Simulate hostile network conditions where no outbound connections are allowed — useful for testing fallback logic, persistence mechanisms, or C2 evasion strategies in red team ops.

- **Perfect for:** Pentesters, red teamers, adversary simulation  
- **Benefit:** Realistic zero-trust environment without needing a physical airgap

---

## 3. Privacy-Aware Software & Telemetry Auditing
Analyze the hidden network behavior of closed-source or commercial software. `vnet` silently blocks all real traffic while optionally logging all attempted connections — ideal for catching unauthorized data exfiltration or telemetry.

- **Perfect for:** Privacy advocates, OSS reviewers, security auditors  
- **Benefit:** Discover hidden "phone home" behavior with zero data leakage


# Requirements
    • Bash/sh compatible shell
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
