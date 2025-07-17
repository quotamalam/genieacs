#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
local_ip=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}============================================================================${NC}"
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
echo -e "${RED}${NC}"
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

# Deteksi arsitektur sistem
ARCH=$(uname -m)
echo -e "${GREEN}Arsitektur sistem terdeteksi: $ARCH${NC}"

# Fungsi untuk menginstall dependensi dasar
install_basic_dependencies() {
    echo -e "${GREEN}Menginstall dependensi dasar...${NC}"
    sudo apt-get update
    sudo apt-get install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates
}

# Install dependensi dasar
install_basic_dependencies

#MongoDB
if ! sudo systemctl is-active --quiet mongod; then
    echo -e "${GREEN}Memulai instalasi MongoDB...${NC}"
    
    # Deteksi dan instalasi MongoDB berdasarkan arsitektur
    case $ARCH in
        x86_64)
            echo -e "${GREEN}Menginstall MongoDB untuk AMD64/x86_64${NC}"
            # Tentukan codename, gunakan focal jika jammy
            if [[ "$(lsb_release -cs)" == "jammy" ]]; then
              CODENAME="focal"
            else
              CODENAME="$(lsb_release -cs)"
            fi
            # Download GPG key ke keyring
            wget -qO /usr/share/keyrings/mongodb-server-6.0.gpg https://www.mongodb.org/static/pgp/server-6.0.asc
            # Tambahkan repository dengan signed-by
            echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $CODENAME/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
            sudo apt-get update
            sudo apt-get install -y mongodb-org
            ;;
        aarch64|arm64)
            echo -e "${GREEN}Menginstall MongoDB untuk ARM64${NC}"
            if [[ "$(lsb_release -cs)" == "jammy" ]]; then
              CODENAME="focal"
            else
              CODENAME="$(lsb_release -cs)"
            fi
            wget -qO /usr/share/keyrings/mongodb-server-6.0.gpg https://www.mongodb.org/static/pgp/server-6.0.asc
            echo "deb [ arch=arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $CODENAME/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
            sudo apt-get update
            sudo apt-get install -y mongodb-org
            ;;
        armv7l|armhf)
            echo -e "${GREEN}Menginstall MongoDB untuk ARM32${NC}"
            sudo apt-get update
            sudo apt-get install -y mongodb
            ;;
        *)
            echo -e "${RED}Arsitektur $ARCH tidak didukung untuk MongoDB${NC}"
            exit 1
            ;;
    esac
    
    # Verifikasi instalasi
    if ! sudo systemctl start mongod; then
        echo -e "${RED}Gagal memulai MongoDB. Mencoba alternatif konfigurasi...${NC}"
        sudo mkdir -p /data/db
        sudo chown -R mongodb:mongodb /data/db
        sudo systemctl enable mongod
        sudo systemctl restart mongod
    fi
else
    echo -e "${GREEN}MongoDB sudah terinstall sebelumnya.${NC}"
fi

# Verifikasi status MongoDB
if ! sudo systemctl is-active --quiet mongod; then
    echo -e "${RED}Instalasi MongoDB gagal. Mohon periksa log: sudo journalctl -u mongod${NC}"
    exit 1
fi

# Fungsi untuk mengecek versi Node.js
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

# Install Node.js
if ! check_node_version; then
    echo -e "${GREEN}Menginstall Node.js v20.x...${NC}"
    # Install Node.js 20.x
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs

    # Verifikasi instalasi Node.js
    if ! check_node_version; then
        echo -e "${RED}Instalasi Node.js v20.x gagal${NC}"
        exit 1
    fi
else
    NODE_VERSION=$(node -v | cut -d 'v' -f 2)
    echo -e "${GREEN}Node.js v$NODE_VERSION sudah terinstall (>= v20)${NC}"
fi

# Install GenieACS
echo -e "${GREEN}Menginstall GenieACS...${NC}"
sudo npm install -g genieacs@1.2.13

# Buat service files untuk GenieACS
echo -e "${GREEN}Membuat service files untuk GenieACS...${NC}"
sudo tee /lib/systemd/system/genieacs-cwmp.service << EOF
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
User=genieacs
Environment=NODE_ENV=production
ExecStart=/usr/bin/genieacs-cwmp

[Install]
WantedBy=multi-user.target
EOF

sudo tee /lib/systemd/system/genieacs-nbi.service << EOF
[Unit]
Description=GenieACS NBI
After=network.target

[Service]
User=genieacs
Environment=NODE_ENV=production
ExecStart=/usr/bin/genieacs-nbi

[Install]
WantedBy=multi-user.target
EOF

sudo tee /lib/systemd/system/genieacs-fs.service << EOF
[Unit]
Description=GenieACS FS
After=network.target

[Service]
User=genieacs
Environment=NODE_ENV=production
ExecStart=/usr/bin/genieacs-fs

[Install]
WantedBy=multi-user.target
EOF

sudo tee /lib/systemd/system/genieacs-ui.service << EOF
[Unit]
Description=GenieACS UI
After=network.target

[Service]
User=genieacs
Environment=NODE_ENV=production
ExecStart=/usr/bin/genieacs-ui

[Install]
WantedBy=multi-user.target
EOF

# Buat user genieacs
sudo useradd -r genieacs || true

# Reload systemd dan enable services
sudo systemctl daemon-reload
sudo systemctl enable genieacs-cwmp
sudo systemctl enable genieacs-nbi
sudo systemctl enable genieacs-fs
sudo systemctl enable genieacs-ui

# Start services
sudo systemctl start genieacs-cwmp
sudo systemctl start genieacs-nbi
sudo systemctl start genieacs-fs
sudo systemctl start genieacs-ui

echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}Instalasi GenieACS selesai!${NC}"
echo -e "${GREEN}Akses UI di: http://$local_ip:3000${NC}"
echo -e "${GREEN}Username: admin${NC}"
echo -e "${GREEN}Password: admin${NC}"
echo -e "${GREEN}============================================================================${NC}"

#Sukses
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
echo -e "${GREEN}=================== Informasi: Whatsapp 081947215703 =======================${NC}"
echo -e "${GREEN}============================================================================${NC}"
cp -r app-LU66VFYW.css /usr/lib/node_modules/genieacs/public/
cp -r logo-3976e73d.svg /usr/lib/node_modules/genieacs/public/
echo -e "${GREEN}Sekarang install parameter. Apakah anda ingin melanjutkan? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${GREEN}Install dibatalkan..${NC}"
    
    exit 1
fi
for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Lanjut Install Parameter $i. Tekan ctrl+c untuk membatalkan"
done

cd 
sudo mongodump --db=genieacs --out genieacs-backup
sudo mongorestore --db=genieacs --drop genieacs
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}=================== VIRTUAL PARAMETER BERHASIL DI INSTALL. =================${NC}"
echo -e "${GREEN}===Jika ACS URL berbeda, silahkan edit di Admin >> Provosions >> inform ====${NC}"
echo -e "${GREEN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
echo -e "${GREEN}=================== Informasi: Whatsapp 081947215703 =======================${NC}"
echo -e "${GREEN}============================================================================${NC}"

cd
sudo rm -r genieacs
