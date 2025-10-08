#!/bin/bash
# ================================================
# 🌀 GENIEACS AUTO INSTALLER - ALIJAYA EDITION 🌀
# Based on: Safrinnetwork/GACS-Ubuntu-22.04
# Modified by: QuotaMalam (github.com/quotamalam)
# ================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
local_ip=$(hostname -I | awk '{print $1}')

clear
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}     GENIEACS INSTALLER - ALIJAYA EDITION     ${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}This script will install GenieACS + parameters${NC}"
echo -e "${GREEN}==============================================${NC}"
read -p "Lanjutkan instalasi? (y/n): " confirm
if [ "$confirm" != "y" ]; then
  echo "❌ Dibatalkan."
  exit 1
fi

# -----------------------------------------------
# 1. Install dependencies
# -----------------------------------------------
echo -e "${GREEN}🔧 Memastikan NodeJS, MongoDB, dan tools dasar...${NC}"
apt update -y
apt install -y curl gnupg build-essential wget git

# NodeJS 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# MongoDB 6.0
if ! systemctl is-active --quiet mongod; then
  curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb.gpg
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
  apt update
  apt install -y mongodb-org
  systemctl enable --now mongod
fi

# -----------------------------------------------
# 2. Install GenieACS
# -----------------------------------------------
echo -e "${GREEN}🚀 Menginstall GenieACS...${NC}"
npm install -g genieacs@1.2.13

# Buat user dan folder
useradd --system --no-create-home --user-group genieacs || true
mkdir -p /opt/genieacs/ext
mkdir -p /var/log/genieacs
chown -R genieacs:genieacs /opt/genieacs /var/log/genieacs

# -----------------------------------------------
# 3. Konfigurasi Environment
# -----------------------------------------------
cat << EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret_alijaya
GENIEACS_UI_BASIC_AUTH=admin:admin
GENIEACS_UI_TITLE="GenieACS Dark - Alijaya Edition"
GENIEACS_DEBUG=true
EOF

chown genieacs:genieacs /opt/genieacs/genieacs.env
chmod 600 /opt/genieacs/genieacs.env

# -----------------------------------------------
# 4. Systemd Service Units
# -----------------------------------------------
for svc in cwmp nbi fs ui; do
cat << EOF > /etc/systemd/system/genieacs-$svc.service
[Unit]
Description=GenieACS $svc
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-$svc

[Install]
WantedBy=multi-user.target
EOF
done

systemctl daemon-reload
systemctl enable --now genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui

# -----------------------------------------------
# 5. Restore Parameter (optional)
# -----------------------------------------------
if [ -d "./parameter_backup/genieacs" ]; then
  echo -e "${GREEN}📦 Restore parameter DB dari backup lokal...${NC}"
  mongorestore --db=genieacs --drop ./parameter_backup/genieacs
else
  echo -e "${RED}⚠️ Tidak ada folder ./parameter_backup ditemukan. Lewati restore.${NC}"
fi

# -----------------------------------------------
# 6. Apply Dark Mode (CSS patch)
# -----------------------------------------------
echo -e "${GREEN}🎨 Mengaktifkan dark mode di UI...${NC}"
UI_PATH=$(npm root -g)/genieacs/public
if [ -d "$UI_PATH" ]; then
cat << 'CSS' > "$UI_PATH/darkmode.css"
body { background-color: #121212 !important; color: #e0e0e0 !important; }
.navbar, .header, .panel-heading { background-color: #1f1f1f !important; }
a, .btn-link { color: #80cbc4 !important; }
CSS
  echo '<link rel="stylesheet" href="darkmode.css">' >> "$UI_PATH/index.html"
fi

# -----------------------------------------------
# 7. Finish
# -----------------------------------------------
systemctl restart genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui

echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}✅ Instalasi selesai!${NC}"
echo -e "${GREEN}UI:     http://$local_ip:3000${NC}"
echo -e "${GREEN}Login:  admin / admin${NC}"
echo -e "${GREEN}==============================================${NC}"
