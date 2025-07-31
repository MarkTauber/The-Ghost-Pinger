# Ghost Pinger - Silent Local Network Scanner (for Internal Threat Scenarios)

![Windows Batch](https://img.shields.io/badge/Windows-Batch-blue)
![No Dependencies](https://img.shields.io/badge/No_Dependencies-None-green)
![Stealth Mode](https://img.shields.io/badge/Mode-Stealth-yellow)

## 🌐 Language Versions

- 🇬🇧 [English (default)](Readme.md)
- 🇷🇺 [Русский](Readme_ru.md)
- 🇨🇳 [中文](Readme_ch.md)

**Ghost Pinger** is a standalone Windows batch script (`cmd`) designed for network reconnaissance by an internal attacker. It detects active hosts in a local network without third-party tools, making it ideal for restricted environments with minimal privileges and strict security controls.

> This project is intended for use in scenarios where installing or running tools like `nmap`, `PowerShell` scripts, or other utilities is impossible.

---

<br>

## Purpose

The script performs silent IP range scanning via ICMP (ping) requests and automatically:
- Detects active hosts
- Collects MAC addresses using the ARP table
- Logs results to a timestamped file
- Supports multiple input methods
- Allows flexible scan settings (timeout, retry count)

Used in early pivoting stages, when an attacker already has access to the internal network but needs a map of active devices for further exploration.

---

<br>

## Features

### Supported Scanning Modes
- Manual IP range (e.g., `192.168.1`)
- Range with count (e.g., `192.168.1.10-50`)
- Common local networks:
  - `192.168.1.0/24`
  - `192.168.0.0/24`
  - `10.0.0.0/8`
  - `172.16.0.0/12`
- CIDR notation (e.g., `192.168.10.0/24`) with accurate subnet and broadcast address calculation

### Additional Capabilities
- Auto-detects local IP address
- Configurable ping timeout and attempt count
- Saves results to `.txt` with timestamp
- Displays statistics: active hosts, success rate
- View or open log file after scan
- Supports repeated scans without restart

### Data Collection
- Records active IP addresses
- Extracts MAC addresses via `arp -a`
- Generates a complete scan report

---

<br>

## Requirements

- OS: Windows 7 / 8 / 10 / 11 / Server (x86 or x64)
- Built-in tools required:
  - `ping.exe`
  - `ipconfig.exe`
  - `arp.exe`
  - `wmic.exe` (for timestamp)
- Privileges: Runs under standard user account (no admin rights)
- Limitations: No external dependencies or installation required

> Note: If `wmic` is disabled, the timestamp will be skipped, but the script will continue to function.

---

<br>

## How to Use

1. Copy `GhostPinger.bat` to the target system (e.g., from a USB drive).
2. Run by double-clicking or via `cmd`.
3. Select IP range input method:
   - Manual
   - CIDR
   - Predefined networks
4. Configure scan settings:
   - Ping timeout (ms)
   - Number of attempts
5. Start the scan.
6. Results are saved to `scan_results_YYYY-MM-DD_HH-MM-SS.txt`.

After completion:
- View results in console
- Open log in Notepad
- Start a new scan

---

<br>

## Example Output

```
SCAN CONFIGURATION
Network: 192.168.1.1 to 192.168.1.254
Ping timeout: 1000ms
Ping attempts: 1
Total hosts to scan: 254
Output file: scan_results_2025-01-31_15-15-56.txt
```

**In the result file:**
```
Network Scan Results 
==================== 
Network: 192.168.1.1-10
Range: 192.168.1.1-10
Date: 31.01.2025 15:15:15,15
Ping timeout: 1000ms 
Ping attempts: 1 
Total hosts to scan: 510 
================================================ 

192.168.1.1 - ACTIVE
  MAC: 00-11-22-33-44-55     динамический 

192.168.1.10 - ACTIVE
  MAC: aa-bb-cc-dd-ee-ff     динамический 

================================================ 
SCAN STATISTICS 
================================================ 
Active hosts: 2 
Total hosts scanned: 10
Success rate: 20% 
Scan completed: 31.01.2025 15:15:56,78 
```

---

<br>

---

## Advantages

| Plus | Description |
|------|-------------|
| **No dependencies** | Uses only built-in Windows tools |
| **No admin rights** | Runs under standard user |
| **Stealthy** | Minimal network noise, ICMP only |
| **Self-contained** | Ready to run - no compilation or setup |
| **CIDR support** | Accurately handles subnets of any size |
| **Logging** | Automatic result saving with timestamp |

---

<br>

## Limitations and Risks

| Downside | Description |
|--------|-------------|
| **ICMP only** | Won't detect hosts blocking ping |
| **No multithreading** | Scanning can be slow (especially in large networks) |
| **No port analysis** | Only checks host reachability |
| **ARP may be empty** | MAC address not resolved if no prior communication |
| **Relies on wmic** | May fail in environments where `wmic` is disabled |

---

<br>

## Usage Recommendations

- Run on a "clean" system after initial access.
- Combine with other methods: after scanning, try connecting to SMB, HTTP, RDP.
- Use short ranges to minimize scan time and network noise.
- Obfuscate the filename (e.g., `update.bat`, `diag_tool.cmd`).
- Exfiltrate results via covert channels (e.g., DNS tunneling, USB).

---

<br>

## Project structure

```
GhostPinger/
├── Ghost_pinger.bat # Main script with menu
├── Ghost_min.bat # Stripped-down version
├── README.md # Documentation (English)
├── README_ru.md # Russian version
└── README_ch.md # Chinese version
```

<br>
<br>

---

> **Ghost Pinger** - your silent flashlight in the dark corporate network.  
> Turn it on - and find out who else is "alive" nearby.
