#!/usr/bin/env bash
# Installs duo-bot as a systemd service on a Raspberry Pi. Run from the repo folder.
set -euo pipefail
cd "$(dirname "$0")"
DIR="$(pwd)"

python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))' \
  || { echo "duo-bot needs Python 3.11+ (Raspberry Pi OS Bookworm or newer)."; exit 1; }
[ -f config.toml ] || { echo "Create config.toml first: cp config.example.toml config.toml"; exit 1; }

sudo tee /etc/systemd/system/duo-bot.service >/dev/null <<UNIT
[Unit]
Description=duo-bot Apple Store stock alerts
After=network-online.target
Wants=network-online.target

[Service]
User=$(id -un)
WorkingDirectory=$DIR
ExecStart=/usr/bin/python3 $DIR/duo_bot.py run --config $DIR/config.toml
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now duo-bot
echo "Running. Follow the log with: journalctl -u duo-bot -f"
