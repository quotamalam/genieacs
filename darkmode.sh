#!/bin/bash
# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to run command with progress
run_command() {
    local cmd="$1"
    local msg="$2"
    printf "${YELLOW}%-60s${NC}" "$msg..."
    eval "$cmd" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Done${NC}"
    else
        echo -e "${RED}Failed${NC}"
        exit 1
    fi
}

# Print banner
print_banner() {
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}=========== AAA   LL      IIIII     JJJ   AAA   YY   YY   AAA ==============${NC}"   
    echo -e "${GREEN}========== AAAAA  LL       III      JJJ  AAAAA  YY   YY  AAAAA =============${NC}" 
    echo -e "${GREEN}========= AA   AA LL       III      JJJ AA   AA  YYYYY  AA   AA ============${NC}"
    echo -e "${GREEN}========= AAAAAAA LL       III  JJ  JJJ AAAAAAA   YYY   AAAAAAA ============${NC}"
    echo -e "${GREEN}========= AA   AA LLLLLLL IIIII  JJJJJ  AA   AA   YYY   AA   AA ============${NC}"
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}========================= . Info 081-947-215-703 ===========================${NC}"
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}============================== WARNING!!! ==================================${NC}"
    echo -e "${GREEN}${NC}"
    echo -e "${GREEN}CONFIG DEMO VERSION${NC}"
    echo -e "${GREEN}Autoinstall GenieACS.${NC}"
    echo -e "${GREEN}${NC}"
    echo -e "${GREEN}=============================================================================${NC}"
}

# Check for root access
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

print_banner

local_ip=$(hostname -I | awk '{print $1}')

# Konfirmasi user
echo -e "${GREEN}Sebelum melanjutkan, silahkan baca terlebih dahulu. Apakah anda ingin melanjutkan? (y/n)${NC}"
read confirmation
if [ "$confirmation" != "y" ]; then
    echo -e "${GREEN}Install dibatalkan. Tidak ada perubahan dalam ubuntu server anda.${NC}"
    exit 1
fi
for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Melanjutkan dalam $i. Tekan ctrl+c untuk membatalkan"
done

ARCH=$(uname -m)
echo -e "${GREEN}Arsitektur sistem terdeteksi: $ARCH${NC}"

run_command "apt-get update" "Updating package list"
run_command "apt-get install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates build-essential git" "Installing basic dependencies"

# MongoDB
if ! systemctl is-active --quiet mongod; then
    echo -e "${GREEN}Memulai instalasi MongoDB...${NC}"
    case $ARCH in
        x86_64)
            if [[ "$(lsb_release -cs)" == "jammy" ]]; then
              CODENAME="focal"
            else
              CODENAME="$(lsb_release -cs)"
            fi
            run_command "wget -qO /usr/share/keyrings/mongodb-server-6.0.gpg https://www.mongodb.org/static/pgp/server-6.0.asc" "Downloading MongoDB GPG key"
            echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $CODENAME/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null
            run_command "apt-get update" "Updating package list for MongoDB"
            run_command "apt-get install -y mongodb-org" "Installing MongoDB"
            ;;
        aarch64|arm64)
            if [[ "$(lsb_release -cs)" == "jammy" ]]; then
              CODENAME="focal"
            else
              CODENAME="$(lsb_release -cs)"
            fi
            run_command "wget -qO /usr/share/keyrings/mongodb-server-6.0.gpg https://www.mongodb.org/static/pgp/server-6.0.asc" "Downloading MongoDB GPG key"
            echo "deb [ arch=arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $CODENAME/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null
            run_command "apt-get update" "Updating package list for MongoDB"
            run_command "apt-get install -y mongodb-org" "Installing MongoDB"
            ;;
        armv7l|armhf)
            run_command "apt-get update" "Updating package list for MongoDB (ARM32)"
            run_command "apt-get install -y mongodb" "Installing MongoDB (ARM32)"
            ;;
        *)
            echo -e "${RED}Arsitektur $ARCH tidak didukung untuk MongoDB${NC}"
            exit 1
            ;;
    esac
    run_command "systemctl start mongod" "Starting MongoDB service"
    run_command "systemctl enable mongod" "Enabling MongoDB service"
else
    echo -e "${GREEN}MongoDB sudah terinstall sebelumnya.${NC}"
fi

if ! systemctl is-active --quiet mongod; then
    echo -e "${RED}Instalasi MongoDB gagal. Mohon periksa log: sudo journalctl -u mongod${NC}"
    exit 1
fi

# Node.js v20
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
    echo -e "${GREEN}Menginstall Node.js v20.x...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    run_command "apt-get install -y nodejs" "Installing Node.js v20.x"
    if ! check_node_version; then
        echo -e "${RED}Instalasi Node.js v20.x gagal${NC}"
        exit 1
    fi
else
    NODE_VERSION=$(node -v | cut -d 'v' -f 2)
    echo -e "${GREEN}Node.js v$NODE_VERSION sudah terinstall (>= v20)${NC}"
fi

# Install GenieACS
run_command "npm install -g genieacs@1.2.13" "Installing GenieACS"

# Buat user genieacs
run_command "useradd -r genieacs || true" "Creating genieacs user"

# Buat direktori dan environment file
run_command "mkdir -p /opt/genieacs/ext && chown genieacs:genieacs /opt/genieacs/ext" "Creating GenieACS directories"
cat << EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
NODE_OPTIONS=--enable-source-maps
GENIEACS_EXT_DIR=/opt/genieacs/ext
EOF
run_command "chown genieacs:genieacs /opt/genieacs/genieacs.env && chmod 600 /opt/genieacs/genieacs.env" "Setting genieacs.env permissions"

# Generate JWT secret
node -e "console.log('GENIEACS_UI_JWT_SECRET=' + require('crypto').randomBytes(128).toString('hex'))" >> /opt/genieacs/genieacs.env

# Buat log directory
run_command "mkdir -p /var/log/genieacs && chown genieacs:genieacs /var/log/genieacs" "Creating log directory"

# Buat systemd service files
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
    echo -e "${YELLOW}Creating genieacs-$service service file... ${GREEN}Done${NC}"
done

# Buat logrotate configuration
cat << EOF > /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}
EOF

# Enable and start services
for service in cwmp nbi fs ui; do
    run_command "systemctl daemon-reload" "Reloading systemd for $service"
    run_command "systemctl enable genieacs-$service" "Enabling genieacs-$service"
    run_command "systemctl start genieacs-$service" "Starting genieacs-$service"
done

# Cek status service
for service in mongod genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui; do
    status=$(systemctl is-active $service)
    if [ "$status" = "active" ]; then
        echo -e "${GREEN}✔ $service is running${NC}"
    else
        echo -e "${RED}✘ $service is not running${NC}"
    fi
done

echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}Instalasi GenieACS selesai!${NC}"
echo -e "${GREEN}Akses UI di: http://$local_ip:3000${NC}"
echo -e "${GREEN}Username: admin${NC}"
echo -e "${GREEN}Password: admin${NC}"
echo -e "${GREEN}============================================================================${NC}"

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

echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}=================== VIRTUAL PARAMETER BERHASIL DI INSTALL. =================${NC}"
echo -e "${GREEN}===Jika ACS URL berbeda, silahkan edit di Admin >> Provisions >> inform ====${NC}"
echo -e "${GREEN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
echo -e "${GREEN}=================== Informasi: Whatsapp 081947215703 =======================${NC}"
echo -e "${GREEN}============================================================================${NC}"
