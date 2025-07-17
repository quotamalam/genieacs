#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to display spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "${CYAN} [%c]  ${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to run command with progress
run_command() {
    local cmd="$1"
    local msg="$2"
    printf "${YELLOW}%-60s${NC}" "$msg..."
    eval "$cmd" > /dev/null 2>&1 &
    spinner $!
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Done${NC}"
    else
        echo -e "${RED}Failed${NC}"
        exit 1
    fi
}

# Print banner
print_banner() {
    echo -e "${BLUE}${BOLD}"
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}==================== Script Install GenieACS All In One. ===================${NC}"
    echo -e "${GREEN}======================== NodeJS, MongoDB, GenieACS, ========================${NC}"
    echo -e "${GREEN}===================== By Alijaya-Net. Info 081947215703=====================${NC}"
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}Apakah anda ingin melanjutkan? (y/n)${NC}"
    echo "                                  --- Ubuntu 20.04/22.04 ---"
    echo "                                      --- By alijaya ---"
    echo -e "${NC}"
}

# Check for root access
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

print_banner

local_ip=$(hostname -I | awk '{print $1}')

total_steps=30
current_step=0

echo -e "\n${MAGENTA}${BOLD}Starting GenieACS Installation Process${NC}\n"

run_command "apt-get update -y" "Updating system ($(( ++current_step ))/$total_steps)"
run_command "apt-get install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates build-essential git" "Installing basic dependencies ($(( ++current_step ))/$total_steps)"

# Node.js v20.x
check_node_version() {
    if ! command -v node &> /dev/null; then
        return 1
    fi
    NODE_VERSION=$(node -v | cut -d 'v' -f 2)
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d '.' -f 1)
    if [ $MAJOR_VERSION -lt 20 ]; then
        return 1
    fi
    return 0
}
if ! check_node_version; then
    run_command "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -" "Adding Node.js v20.x repository ($(( ++current_step ))/$total_steps)"
    run_command "apt-get install -y nodejs" "Installing Node.js v20.x ($(( ++current_step ))/$total_steps)"
else
    NODE_VERSION=$(node -v | cut -d 'v' -f 2)
    echo -e "${GREEN}Node.js v$NODE_VERSION sudah terinstall (>= v20)${NC}"
    current_step=$((current_step+2))
fi

run_command "npm install -g npm" "Upgrading npm ($(( ++current_step ))/$total_steps)"

# MongoDB
ARCH=$(uname -m)
if ! systemctl is-active --quiet mongod; then
    case $ARCH in
        x86_64)
            if [[ "$(lsb_release -cs)" == "jammy" ]]; then
              CODENAME="focal"
            else
              CODENAME="$(lsb_release -cs)"
            fi
            run_command "wget -qO /usr/share/keyrings/mongodb-server-6.0.gpg https://www.mongodb.org/static/pgp/server-6.0.asc" "Downloading MongoDB GPG key ($(( ++current_step ))/$total_steps)"
            echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $CODENAME/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null
            run_command "apt-get update -y" "Updating package list for MongoDB ($(( ++current_step ))/$total_steps)"
            run_command "apt-get install -y mongodb-org" "Installing MongoDB ($(( ++current_step ))/$total_steps)"
            ;;
        aarch64|arm64)
            if [[ "$(lsb_release -cs)" == "jammy" ]]; then
              CODENAME="focal"
            else
              CODENAME="$(lsb_release -cs)"
            fi
            run_command "wget -qO /usr/share/keyrings/mongodb-server-6.0.gpg https://www.mongodb.org/static/pgp/server-6.0.asc" "Downloading MongoDB GPG key ($(( ++current_step ))/$total_steps)"
            echo "deb [ arch=arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $CODENAME/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null
            run_command "apt-get update -y" "Updating package list for MongoDB ($(( ++current_step ))/$total_steps)"
            run_command "apt-get install -y mongodb-org" "Installing MongoDB ($(( ++current_step ))/$total_steps)"
            ;;
        armv7l|armhf)
            run_command "apt-get update -y" "Updating package list for MongoDB (ARM32) ($(( ++current_step ))/$total_steps)"
            run_command "apt-get install -y mongodb" "Installing MongoDB (ARM32) ($(( ++current_step ))/$total_steps)"
            ;;
        *)
            echo -e "${RED}Arsitektur $ARCH tidak didukung untuk MongoDB${NC}"
            exit 1
            ;;
    esac
    run_command "systemctl start mongod" "Starting MongoDB service ($(( ++current_step ))/$total_steps)"
    run_command "systemctl enable mongod" "Enabling MongoDB service ($(( ++current_step ))/$total_steps)"
else
    echo -e "${GREEN}MongoDB sudah terinstall sebelumnya.${NC}"
    current_step=$((current_step+6))
fi

# GenieACS
run_command "npm install -g genieacs@1.2.13" "Installing GenieACS ($(( ++current_step ))/$total_steps)"
run_command "useradd --system --no-create-home --user-group genieacs || true" "Creating GenieACS user ($(( ++current_step ))/$total_steps)"
run_command "mkdir -p /opt/genieacs/ext && chown genieacs:genieacs /opt/genieacs/ext" "Creating GenieACS directories ($(( ++current_step ))/$total_steps)"

cat << EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
NODE_OPTIONS=--enable-source-maps
GENIEACS_EXT_DIR=/opt/genieacs/ext
EOF
echo -e "${YELLOW}Creating genieacs.env file ($(( ++current_step ))/$total_steps)${NC}... ${GREEN}Done${NC}"

run_command "node -e \"console.log('GENIEACS_UI_JWT_SECRET=' + require('crypto').randomBytes(128).toString('hex'))\" >> /opt/genieacs/genieacs.env" "Generating JWT secret ($(( ++current_step ))/$total_steps)"
run_command "chown genieacs:genieacs /opt/genieacs/genieacs.env && chmod 600 /opt/genieacs/genieacs.env" "Setting genieacs.env permissions ($(( ++current_step ))/$total_steps)"
run_command "mkdir -p /var/log/genieacs && chown genieacs:genieacs /var/log/genieacs" "Creating log directory ($(( ++current_step ))/$total_steps)"

for service in cwmp nbi fs ui; do
    cat << EOF > /etc/systemd/system/genieacs-$service.service
[Unit]
Description=GenieACS $service
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=$(command -v genieacs-$service)

[Install]
WantedBy=multi-user.target
EOF
    echo -e "${YELLOW}Creating genieacs-$service service file ($(( ++current_step ))/$total_steps)${NC}... ${GREEN}Done${NC}"
done

cat << EOF > /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}
EOF
echo -e "${YELLOW}Creating logrotate configuration ($(( ++current_step ))/$total_steps)${NC}... ${GREEN}Done${NC}"

for service in cwmp nbi fs ui; do
    run_command "systemctl enable genieacs-$service && systemctl start genieacs-$service" "Enabling and starting genieacs-$service ($(( ++current_step ))/$total_steps)"
done

echo -e "\n${MAGENTA}${BOLD}Checking services status:${NC}"
for service in mongod genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui; do
    status=$(systemctl is-active $service)
    if [ "$status" = "active" ]; then
        echo -e "${GREEN}✔ $service is running${NC}"
    else
        echo -e "${RED}✘ $service is not running${NC}"
    fi
done

echo -e "\n${GREEN}${BOLD}Script execution completed successfully!${NC}"

# Konfirmasi restore parameter
echo -e "${GREEN}Sekarang install parameter. Apakah anda ingin melanjutkan? (y/n)${NC}"
read confirmation
if [ "$confirmation" != "y" ]; then
    echo -e "${GREEN}Install parameter dibatalkan..${NC}"
    exit 1
fi
for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Lanjut Install Parameter $i. Tekan ctrl+c untuk membatalkan"
done

cd
run_command "mongodump --db=genieacs --out genieacs-backup" "Backup database GenieACS (mongodump)"
run_command "mongorestore --db=genieacs --drop genieacs" "Restore parameter database GenieACS (mongorestore)"

cat << EOF
${GREEN}============================================================================${NC}
${GREEN}=================== VIRTUAL PARAMETER BERHASIL DI INSTALL. =================${NC}
${GREEN}===Jika ACS URL berbeda, silahkan edit di Admin >> Provisions >> inform ====${NC}
${GREEN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}
${GREEN}=================== Informasi: Whatsapp 081947215703 =======================${NC}
${GREEN}============================================================================${NC}
EOF
