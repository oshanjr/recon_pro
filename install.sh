cat << 'EOF' > install.sh
#!/bin/bash

# recon-pro installation script (Kali Linux Optimized)
# Installs required dependencies: jq, curl, Go, subfinder, httpx-toolkit, nuclei

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[*] Starting Recon-Pro dependency installation...${NC}"

# Check for root/sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}[*] Requesting sudo privileges for apt package installation...${NC}"
  sudo -v
fi

# Install base packages and httpx-toolkit
echo -e "${YELLOW}[*] Installing base packages and httpx-toolkit...${NC}"
sudo apt-get update
sudo apt-get install -y curl jq unzip git httpx-toolkit

# Install Go if not present
if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}[*] Go is not installed. Installing Go...${NC}"
    sudo apt-get install -y golang
else
    echo -e "${GREEN}[✓] Go is already installed.${NC}"
fi

# Ensure Go bin path is in environment
export PATH=$PATH:$HOME/go/bin
if ! grep -q "$HOME/go/bin" ~/.bashrc; then
    echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    echo -e "${YELLOW}[*] Added $HOME/go/bin to ~/.bashrc${NC}"
fi

# Install ProjectDiscovery tools via Go
echo -e "${YELLOW}[*] Installing subfinder...${NC}"
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

echo -e "${YELLOW}[*] Installing nuclei...${NC}"
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

# Update nuclei templates
if command -v nuclei &> /dev/null; then
    echo -e "${YELLOW}[*] Updating nuclei templates...${NC}"
    nuclei -update-templates -silent
fi

echo -e "${GREEN}[✓] Installation complete!${NC}"
echo -e "${YELLOW}[!] Please run 'source ~/.bashrc' or restart your terminal to apply path changes.${NC}"
EOF
