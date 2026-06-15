#!/bin/sh
set -e

# OpenAppNest Agent Install Script
# Usage: curl -fsSL <url> | bash -s -- --token <TOKEN> [--endpoint <URL>] [--port <PORT>]

AGENT_TOKEN=""
ENDPOINT=""
AGENT_PORT="9100"
APPS_DIR="/srv/apps"
CADDY_FILE="/etc/caddy/Caddyfile"

while [ $# -gt 0 ]; do
  case "$1" in
    --token) AGENT_TOKEN="$2"; shift 2 ;;
    --endpoint) ENDPOINT="$2"; shift 2 ;;
    --port) AGENT_PORT="$2"; shift 2 ;;
    --apps-dir) APPS_DIR="$2"; shift 2 ;;
    --caddy-file) CADDY_FILE="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ -z "$AGENT_TOKEN" ]; then
  echo "Error: --token is required"
  exit 1
fi

echo "=== OpenAppNest Agent Installer ==="
echo ""

# --- Detect OS ---
. /etc/os-release 2>/dev/null || true
OS_ID="${ID:-unknown}"
echo "Detected OS: $OS_ID"

# --- Install Docker if missing ---
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  case "$OS_ID" in
    ubuntu|debian)
      apt-get update -qq && apt-get install -y -qq docker.io docker-compose-v2 2>/dev/null || \
        (curl -fsSL https://get.docker.com | sh)
      ;;
    alpine)
      apk add --no-cache docker docker-compose
      rc-update add docker boot
      service docker start
      ;;
    centos|rhel|fedora)
      yum install -y docker docker-compose-plugin || \
        (curl -fsSL https://get.docker.com | sh)
      ;;
    *)
      curl -fsSL https://get.docker.com | sh
      ;;
  esac
  echo "Docker installed."
else
  echo "Docker already installed."
fi

# --- Install Caddy if missing (optional for HTTPS) ---
if ! command -v caddy >/dev/null 2>&1; then
  echo "Installing Caddy..."
  case "$OS_ID" in
    ubuntu|debian)
      apt-get install -y -qq debian-keyring debian-archive-keyring 2>/dev/null
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
        gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg 2>/dev/null
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | \
        tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
      apt-get update -qq && apt-get install -y -qq caddy 2>/dev/null
      ;;
    *)
      echo "Please install Caddy manually: https://caddyserver.com/docs/install"
      ;;
  esac
else
  echo "Caddy already installed."
fi

# --- Create directories ---
mkdir -p "$APPS_DIR" /etc/openappnest

# --- Download Agent binary ---
echo "Downloading Agent..."
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

AGENT_URL="https://github.com/xixi-zhao/openappnest-agent/raw/main/agent-linux-${ARCH}"

if ! curl -fsSL "$AGENT_URL" -o /usr/local/bin/openappnest-agent 2>/dev/null; then
  echo "Failed to download agent binary from $AGENT_URL"
  echo "Please build from source: https://github.com/xixi-zhao/openappnest"
  exit 1
fi

chmod +x /usr/local/bin/openappnest-agent

# --- Write environment config ---
cat > /etc/openappnest/agent.env << EOF
AGENT_PORT=${AGENT_PORT}
AGENT_TOKEN=${AGENT_TOKEN}
AGENT_ENDPOINT=${ENDPOINT}
APPS_DIR=${APPS_DIR}
CADDY_FILE=${CADDY_FILE}
EOF

# --- Create systemd service ---
cat > /etc/systemd/system/openappnest-agent.service << EOF
[Unit]
Description=OpenAppNest Agent
After=docker.service network-online.target
Wants=docker.service network-online.target

[Service]
Type=simple
EnvironmentFile=/etc/openappnest/agent.env
ExecStart=/usr/local/bin/openappnest-agent
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# --- Start ---
systemctl daemon-reload
systemctl enable openappnest-agent
systemctl start openappnest-agent

echo ""
echo "=== Installation Complete ==="
echo "Agent running on port ${AGENT_PORT}"
echo "Apps directory: ${APPS_DIR}"
echo ""
echo "Check status: systemctl status openappnest-agent"
echo "View logs:    journalctl -u openappnest-agent -f"
