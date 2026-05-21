#!/bin/bash



################################################################################

# Bug Bounty Reconnaissance Automation Script

# Author: oshanjr

# Description: Automated subdomain enumeration, HTTP probing, and vulnerability scanning with analysis

# Usage: ./recon-pro.sh <domain> [options]

################################################################################



# Color codes for output

RED='\033[0;31m'

GREEN='\033[0;32m'

YELLOW='\033[1;33m'

BLUE='\033[0;34m'

PURPLE='\033[0;35m'

CYAN='\033[0;36m'

NC='\033[0m' # No Color



# Default configuration

THREADS=50

SEVERITY="critical,high,medium"

AI_ENABLED=false

AI_API_KEY=""

AI_PROVIDER="groq" # groq, claude, or gemini

SLACK_WEBHOOK=""

VERBOSE=false



# Tool check

check_tools() {

    local missing_tools=()

    

    command -v subfinder >/dev/null 2>&1 || missing_tools+=("subfinder")

    command -v httpx-toolkit >/dev/null 2>&1 || missing_tools+=("httpx-toolkit")

    command -v nuclei >/dev/null 2>&1 || missing_tools+=("nuclei")

    command -v jq >/dev/null 2>&1 || missing_tools+=("jq")

    

    if [ ${#missing_tools[@]} -ne 0 ]; then

        echo -e "${RED}[!] Missing required tools: ${missing_tools[*]}${NC}"

        echo -e "${YELLOW}[*] Install with: sudo apt install ${missing_tools[*]} -y${NC}"

        exit 1

    fi

}



# Banner

print_banner() {

    echo -e "${CYAN}"

    cat << "EOF"

╦═╗╔═╗╔═╗╔═╗╔╗╔  ╔═╗╦═╗╔═╗

╠╦╝║╣ ║  ║ ║║║║  ╠═╝╠╦╝║ ║

╩╚═╚═╝╚═╝╚═╝╝╚╝  ╩  ╩╚═╚═╝

Bug Bounty Reconnaissance v2.0

EOF

    echo -e "${NC}"

}



# Help menu

show_help() {

    cat << EOF

Usage: ./recon-pro.sh <domain> [OPTIONS]



Required:

  domain              Target domain (e.g., example.com)



Options:

  -t, --threads       Number of threads (default: 50)

  -s, --severity      Nuclei severity levels (default: critical,high,medium)

  -a, --ai            Enable AI analysis (requires API key)

  -k, --api-key       AI API key

  -p, --provider      AI provider: groq|claude|gemini (default: groq)

  -w, --webhook       Slack webhook URL for notifications

  -v, --verbose       Verbose output

  -h, --help          Show this help message



Examples:

  ./recon-pro.sh example.com

  ./recon-pro.sh example.com -t 100 -s critical,high

  ./recon-pro.sh example.com -a -k YOUR_API_KEY -p groq

  ./recon-pro.sh example.com -w https://hooks.slack.com/services/YOUR/WEBHOOK



EOF

    exit 0

}



# Parse arguments

DOMAIN=""

while [[ $# -gt 0 ]]; do

    case $1 in

        -t|--threads)

            THREADS="$2"

            shift 2

            ;;

        -s|--severity)

            SEVERITY="$2"

            shift 2

            ;;

        -a|--ai)

            AI_ENABLED=true

            shift

            ;;

        -k|--api-key)

            AI_API_KEY="$2"

            shift 2

            ;;

        -p|--provider)

            AI_PROVIDER="$2"

            shift 2

            ;;

        -w|--webhook)

            SLACK_WEBHOOK="$2"

            shift 2

            ;;

        -v|--verbose)

            VERBOSE=true

            shift

            ;;

        -h|--help)

            show_help

            ;;

        *)

            if [ -z "$DOMAIN" ]; then

                DOMAIN="$1"

            else

                echo -e "${RED}[!] Unknown option: $1${NC}"

                exit 1

            fi

            shift

            ;;

    esac

done



# Validate domain

if [ -z "$DOMAIN" ]; then

    echo -e "${RED}[!] Error: Domain is required${NC}"

    echo -e "${YELLOW}[*] Use -h for help${NC}"

    exit 1

fi



# Setup

START_TIME=$(date +%s)

OUTPUT_DIR="./recon_${DOMAIN}_$(date +%Y%m%d_%H%M%S)"

LOG_FILE="$OUTPUT_DIR/recon.log"



# Logging function

log() {

    echo -e "$1" | tee -a "$LOG_FILE"

}



# Progress bar

show_progress() {

    local current=$1

    local total=$2

    local prefix=$3

    local percent=$((current * 100 / total))

    local completed=$((percent / 2))

    local remaining=$((50 - completed))

    

    printf "\r${CYAN}${prefix}: [${GREEN}"

    printf "%${completed}s" | tr ' ' '='

    printf "${NC}"

    printf "%${remaining}s" | tr ' ' '-'

    printf "${CYAN}] ${percent}%%${NC}"

}



# Send Slack notification

send_slack() {

    if [ -n "$SLACK_WEBHOOK" ]; then

        local message=$1

        curl -X POST -H 'Content-type: application/json' \

            --data "{\"text\":\"🔍 Recon Update: $message\"}" \

            "$SLACK_WEBHOOK" &>/dev/null

    fi

}



# AI Analysis function

analyze_with_ai() {

    if [ "$AI_ENABLED" = false ] || [ -z "$AI_API_KEY" ]; then

        return

    fi

    

    local vulns_file=$1

    

    if [ ! -s "$vulns_file" ]; then

        log "${YELLOW}[*] No vulnerabilities to analyze${NC}"

        return

    fi

    

    log "${BLUE}[*] Analyzing results with AI ($AI_PROVIDER)...${NC}"

    

    local vulns_content=$(cat "$vulns_file")

    local prompt="Analyze these vulnerability scan results. Prioritize by exploitability and severity. For each finding: 1) Rate exploitability (1-10), 2) Suggest next steps, 3) Identify false positives. Format as JSON array with fields: name, severity, exploitability_score, next_steps, is_false_positive.\n\n$vulns_content"

    

    case $AI_PROVIDER in

        groq)

            curl -s -X POST "https://api.groq.com/openai/v1/chat/completions" \

                -H "Authorization: Bearer $AI_API_KEY" \

                -H "Content-Type: application/json" \

                -d "{

                    \"model\": \"llama-3.1-70b-versatile\",

                    \"messages\": [{\"role\": \"user\", \"content\": $(echo "$prompt" | jq -Rs .)}],

                    \"temperature\": 0.3

                }" | jq -r '.choices[0].message.content' > "$OUTPUT_DIR/ai_analysis.txt"

            ;;

        claude)

            curl -s -X POST "https://api.anthropic.com/v1/messages" \

                -H "x-api-key: $AI_API_KEY" \

                -H "anthropic-version: 2023-06-01" \

                -H "content-type: application/json" \

                -d "{

                    \"model\": \"claude-3-haiku-20240307\",

                    \"max_tokens\": 4096,

                    \"messages\": [{\"role\": \"user\", \"content\": $(echo "$prompt" | jq -Rs .)}]

                }" | jq -r '.content[0].text' > "$OUTPUT_DIR/ai_analysis.txt"

            ;;

        gemini)

            curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$AI_API_KEY" \

                -H "Content-Type: application/json" \

                -d "{

                    \"contents\": [{\"parts\":[{\"text\": $(echo "$prompt" | jq -Rs .)}]}]

                }" | jq -r '.candidates[0].content.parts[0].text' > "$OUTPUT_DIR/ai_analysis.txt"

            ;;

    esac

    

    if [ -s "$OUTPUT_DIR/ai_analysis.txt" ]; then

        log "${GREEN}[✓] AI analysis saved to: ai_analysis.txt${NC}"

        send_slack "AI analysis completed for $DOMAIN"

    else

        log "${RED}[!] AI analysis failed${NC}"

    fi

}



# Generate HTML report

generate_html_report() {

    local subs_count=$(wc -l < "$OUTPUT_DIR/subdomains.txt" 2>/dev/null || echo 0)

    local alive_count=$(wc -l < "$OUTPUT_DIR/alive.txt" 2>/dev/null || echo 0)

    local vulns_count=$(wc -l < "$OUTPUT_DIR/vulnerabilities.txt" 2>/dev/null || echo 0)

    

    cat > "$OUTPUT_DIR/report.html" << EOF

<!DOCTYPE html>

<html>

<head>

    <title>Recon Report - $DOMAIN</title>

    <style>

        body { font-family: 'Segoe UI', Tahoma, sans-serif; margin: 40px; background: #f5f5f5; }

        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; }

        .stats { display: flex; gap: 20px; margin: 20px 0; }

        .stat-box { background: white; padding: 20px; border-radius: 8px; flex: 1; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }

        .stat-number { font-size: 36px; font-weight: bold; color: #667eea; }

        .stat-label { color: #666; margin-top: 5px; }

        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }

        .vuln-item { padding: 15px; margin: 10px 0; border-left: 4px solid #f44336; background: #ffebee; border-radius: 4px; }

        .critical { border-left-color: #d32f2f; background: #ffcdd2; }

        .high { border-left-color: #f57c00; background: #ffe0b2; }

        .medium { border-left-color: #fbc02d; background: #fff9c4; }

        pre { background: #263238; color: #aed581; padding: 15px; border-radius: 5px; overflow-x: auto; }

        .timestamp { color: #999; font-size: 14px; }

    </style>

</head>

<body>

    <div class="header">

        <h1>🔍 Reconnaissance Report</h1>

        <h2>$DOMAIN</h2>

        <p class="timestamp">Generated: $(date)</p>

    </div>

    

    <div class="stats">

        <div class="stat-box">

            <div class="stat-number">$subs_count</div>

            <div class="stat-label">Subdomains Found</div>

        </div>

        <div class="stat-box">

            <div class="stat-number">$alive_count</div>

            <div class="stat-label">Live Targets</div>

        </div>

        <div class="stat-box">

            <div class="stat-number">$vulns_count</div>

            <div class="stat-label">Vulnerabilities</div>

        </div>

    </div>

    

    <div class="section">

        <h3>📊 Scan Summary</h3>

        <p><strong>Target:</strong> $DOMAIN</p>

        <p><strong>Severity Filter:</strong> $SEVERITY</p>

        <p><strong>Threads:</strong> $THREADS</p>

        <p><strong>Duration:</strong> $(($(date +%s) - START_TIME)) seconds</p>

    </div>

    

    <div class="section">

        <h3>🎯 Top Vulnerabilities</h3>

        $(head -20 "$OUTPUT_DIR/vulnerabilities.txt" 2>/dev/null | while read line; do echo "<div class='vuln-item'>$line</div>"; done)

    </div>

    

    <div class="section">

        <h3>🌐 Live Targets</h3>

        <pre>$(head -50 "$OUTPUT_DIR/alive.txt" 2>/dev/null)</pre>

    </div>

</body>

</html>

EOF

    log "${GREEN}[✓] HTML report generated: report.html${NC}"

}



# Main execution

main() {

    print_banner

    check_tools

    

    # Create output directory

    mkdir -p "$OUTPUT_DIR"

    

    log "${BLUE}[*] Target: $DOMAIN${NC}"

    log "${BLUE}[*] Output directory: $OUTPUT_DIR${NC}"

    log "${BLUE}[*] Threads: $THREADS${NC}"

    log "${BLUE}[*] Severity: $SEVERITY${NC}"

    echo ""

    

    send_slack "Starting reconnaissance on $DOMAIN"

    

    # Step 1: Subdomain Enumeration

    log "${PURPLE}[1/4] Subdomain Enumeration${NC}"

    subfinder -d "$DOMAIN" -silent -o "$OUTPUT_DIR/subdomains.txt" 2>/dev/null &

    SUBFINDER_PID=$!

    

    while kill -0 $SUBFINDER_PID 2>/dev/null; do

        sleep 0.5

        printf "\r${CYAN}[*] Finding subdomains... ${NC}"

    done

    wait $SUBFINDER_PID

    

    SUBS_COUNT=$(wc -l < "$OUTPUT_DIR/subdomains.txt" 2>/dev/null || echo 0)

    log "\r${GREEN}[✓] Found $SUBS_COUNT subdomains${NC}"

    

    if [ "$SUBS_COUNT" -eq 0 ]; then

        log "${RED}[!] No subdomains found. Exiting.${NC}"

        exit 1

    fi

    

    # Step 2: HTTP Probing

    log "${PURPLE}[2/4] HTTP Probing${NC}"

    cat "$OUTPUT_DIR/subdomains.txt" | httpx-toolkit -silent -threads "$THREADS" -o "$OUTPUT_DIR/alive.txt" 2>/dev/null

    ALIVE_COUNT=$(wc -l < "$OUTPUT_DIR/alive.txt" 2>/dev/null || echo 0)

    log "${GREEN}[✓] Found $ALIVE_COUNT live targets${NC}"

    

    if [ "$ALIVE_COUNT" -eq 0 ]; then

        log "${YELLOW}[!] No live targets found. Exiting.${NC}"

        exit 0

    fi

    

    # Step 3: Vulnerability Scanning

    log "${PURPLE}[3/4] Vulnerability Scanning${NC}"

    nuclei -l "$OUTPUT_DIR/alive.txt" \

        -severity "$SEVERITY" \

        -silent \

        -stats \

        -metrics \

        -o "$OUTPUT_DIR/vulnerabilities.txt" 2>/dev/null

    

    VULNS_COUNT=$(wc -l < "$OUTPUT_DIR/vulnerabilities.txt" 2>/dev/null || echo 0)

    log "${GREEN}[✓] Found $VULNS_COUNT potential vulnerabilities${NC}"

    

    # Step 4: AI Analysis (if enabled)

    if [ "$AI_ENABLED" = true ]; then

        log "${PURPLE}[4/4] AI Analysis${NC}"

        analyze_with_ai "$OUTPUT_DIR/vulnerabilities.txt"

    fi

    

    # Generate report

    generate_html_report

    

    # Summary

    END_TIME=$(date +%s)

    DURATION=$((END_TIME - START_TIME))

    

    echo ""

    log "${GREEN}╔════════════════════════════════════╗${NC}"

    log "${GREEN}║        SCAN COMPLETE ✓             ║${NC}"

    log "${GREEN}╚════════════════════════════════════╝${NC}"

    echo ""

    log "${CYAN}📁 Results Directory: $OUTPUT_DIR${NC}"

    log "${CYAN}📊 Subdomains: $SUBS_COUNT${NC}"

    log "${CYAN}🌐 Live Targets: $ALIVE_COUNT${NC}"

    log "${CYAN}🎯 Vulnerabilities: $VULNS_COUNT${NC}"

    log "${CYAN}⏱️  Duration: ${DURATION}s${NC}"

    echo ""

    log "${YELLOW}[!] IMPORTANT: Manually verify all findings before reporting${NC}"

    log "${YELLOW}[!] Never submit automated results without validation${NC}"

    echo ""

    log "${BLUE}📄 Files generated:${NC}"

    log "   - subdomains.txt (all discovered subdomains)"

    log "   - alive.txt (live HTTP/HTTPS targets)"

    log "   - vulnerabilities.txt (nuclei findings)"

    log "   - report.html (visual report)"

    [ -f "$OUTPUT_DIR/ai_analysis.txt" ] && log "   - ai_analysis.txt (AI prioritization)"

    log "   - recon.log (full execution log)"

    

    send_slack "Scan completed for $DOMAIN: $VULNS_COUNT vulnerabilities found"

}



# Run

main
