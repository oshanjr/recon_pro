# 🔍 Recon-Pro

> Automated Bug Bounty Reconnaissance & Vulnerability Analysis Tool

Recon-Pro is a bash-based automation script designed to streamline the reconnaissance phase of bug bounty hunting and penetration testing. It chains together industry-standard tools to perform subdomain enumeration, live host probing, and vulnerability scanning, topped off with optional AI-driven analysis to prioritize findings and filter false positives.

## ✨ Features

* **Subdomain Enumeration:** Utilizes `subfinder` for fast, passive discovery.
* **HTTP Probing:** Uses `httpx` to verify live web servers and filter out dead hosts.
* **Vulnerability Scanning:** Leverages `nuclei` with customizable severity filters.
* **AI Analysis Integration:** Sends findings to Groq, Claude, or Gemini to score exploitability and recommend next steps.
* **Slack Notifications:** Real-time webhook integration to alert you when scans finish or vulnerabilities are found.
* **HTML Reporting:** Generates a clean, standalone HTML report with scan statistics and prioritized findings.

## ⚠️ Disclaimer

**For Authorized Use Only.** This tool is designed strictly for security professionals, penetration testers, and bug bounty hunters to test systems they own or have explicit, written permission to test. The author is not responsible for any misuse, damage, or illegal activities caused by this tool.

## ⚙️ Prerequisites

Recon-Pro relies on several open-source tools. These will be installed automatically via the included installation script, but for reference, it requires:
* `subfinder`
* `httpx`
* `nuclei`
* `jq`
* `curl`

## 🚀 Installation

1. Clone the repository:
   ```bash
   git clone [https://github.com/yourusername/recon-pro.git](https://github.com/yourusername/recon-pro.git)
   cd recon-pro
