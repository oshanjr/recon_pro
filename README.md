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
* `go` (for installation)

## 🚀 Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/oshanjr/recon_pro.git
   cd recon_pro
   ```

2. Make the scripts executable:
   ```bash
   chmod +x recon-pro.sh install.sh
   
```

3. Run the installation script (requires sudo privileges for dependencies):
   ```bash
   ./install.sh
   
```

4. *(Optional)* Set up your environment variables for AI and Slack integration by copying the example config:
   ```bash
   cp .env.example .env
   
```

## 📖 Usage

Basic execution targeting a single domain:
```bash
./recon-pro.sh example.com
```

### Advanced Usage

Run with 100 threads, scanning only for critical and high vulnerabilities:
```bash
./recon-pro.sh example.com -t 100 -s critical,high
```

Enable AI analysis using Groq:
```bash
./recon-pro.sh example.com -a -p groq -k "YOUR_GROQ_API_KEY"
```

Send results to a Slack channel:
```bash
./recon-pro.sh example.com -w "[https://hooks.slack.com/services/T0000/B0000/XXXXX](https://hooks.slack.com/services/T0000/B0000/XXXXX)"
```

### Options Flag Reference

| Flag | Long Flag | Description | Default |
|---|---|---|---|
| `-t` | `--threads` | Number of concurrent threads | `50` |
| `-s` | `--severity` | Nuclei severity levels (comma separated) | `critical,high,medium` |
| `-a` | `--ai` | Enable AI analysis of the results | `false` |
| `-k` | `--api-key` | API key for the chosen AI provider | *None* |
| `-p` | `--provider` | AI provider to use (`groq`, `claude`, `gemini`) | `groq` |
| `-w` | `--webhook` | Slack Webhook URL for alerts | *None* |
| `-v` | `--verbose` | Enable verbose output | `false` |
| `-h` | `--help` | Show the help menu | N/A |

## 📁 Output Structure

Every run creates a timestamped directory (e.g., `recon_example.com_20231025_153000/`) containing:
* `subdomains.txt`: Raw list of discovered subdomains.
* `alive.txt`: Subdomains responding to HTTP/HTTPS.
* `vulnerabilities.txt`: Raw Nuclei output.
* `ai_analysis.txt`: AI insights and prioritization (if enabled).
* `report.html`: Visual summary of the scan.
* `recon.log`: Execution logs.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
