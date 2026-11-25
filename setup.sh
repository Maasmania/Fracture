#!/usr/bin/env bash
# FRACTURE online server installer for Ubuntu (run as root). Re-run any time to update.
#   curl -fsSL https://raw.githubusercontent.com/Maasmania/Fracture/main/setup.sh | bash
set -e
REPO="${FRACTURE_REPO:-Maasmania/Fracture}"; BRANCH="${FRACTURE_BRANCH:-main}"; PORT="${PORT:-7778}"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"
echo "== FRACTURE server setup from $REPO ($BRANCH), port $PORT"
if ! command -v node >/dev/null 2>&1 || [ "$(node -v | cut -c2- | cut -d. -f1)" -lt 18 ]; then
  echo "== installing Node.js 22"
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
fi
mkdir -p /opt/fracture && cd /opt/fracture
curl -fsSL "$RAW/server.js?t=$(date +%s)" -o server.js
curl -fsSL "$RAW/package.json?t=$(date +%s)" -o package.json
npm install --omit=dev --no-audit --no-fund
id -u fracture >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin fracture
chown -R fracture:fracture /opt/fracture
NODE_BIN="$(command -v node)"
cat > /etc/systemd/system/fracture.service <<UNIT
[Unit]
Description=FRACTURE game server
After=network.target
[Service]
WorkingDirectory=/opt/fracture
ExecStart=$NODE_BIN /opt/fracture/server.js
Environment=PORT=$PORT
Restart=always
RestartSec=2
User=fracture
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable fracture >/dev/null 2>&1
systemctl restart fracture
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then ufw allow "$PORT"/tcp >/dev/null; echo "== opened port $PORT in ufw"; fi
sleep 1
echo "== status:"; curl -s "http://localhost:$PORT" || echo "server did not answer yet - check: journalctl -u fracture -n 50"
echo "== done. Players connect to <this server's IP>:$PORT"
