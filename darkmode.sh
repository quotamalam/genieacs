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
echo -e "${GREEN}${NC}"
echo -e "${GREEN}Autoinstall GenieACS.${NC}"
echo -e "${GREEN}${NC}"
echo -e "${GREEN}======================================================================================${NC}"
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

#Install NodeJS
check_node_version() {
    if command -v node > /dev/null 2>&1; then
        NODE_VERSION=$(node -v | cut -d 'v' -f 2)
        NODE_MAJOR_VERSION=$(echo $NODE_VERSION | cut -d '.' -f 1)
        NODE_MINOR_VERSION=$(echo $NODE_VERSION | cut -d '.' -f 2)

        if [ "$NODE_MAJOR_VERSION" -lt 12 ] || { [ "$NODE_MAJOR_VERSION" -eq 12 ] && [ "$NODE_MINOR_VERSION" -lt 13 ]; } || [ "$NODE_MAJOR_VERSION" -gt 22 ]; then
            return 1
        else
            return 0
        fi
    else
        return 1
    fi
}

if ! check_node_version; then
    echo -e "${GREEN}================== Menginstall NodeJS ==================${NC}"
    
    # Check if NodeJS is already installed with lower version
    if command -v node > /dev/null 2>&1; then
        CURRENT_VERSION=$(node -v)
        echo -e "${GREEN}NodeJS versi lama terdeteksi: $CURRENT_VERSION${NC}"
        echo -e "${GREEN}Menghapus versi lama dan menginstall NodeJS v20...${NC}"
        
        # Remove old NodeJS
        apt-get remove -y nodejs npm
        apt-get autoremove -y
        apt-get autoclean
        
        # Remove NodeJS from different sources
        rm -rf /usr/local/bin/npm /usr/local/bin/node
        rm -rf /usr/bin/npm /usr/bin/node
        rm -rf ~/.npm
        rm -rf /usr/local/lib/node_modules
        rm -rf /usr/lib/node_modules
        
        echo -e "${GREEN}NodeJS versi lama berhasil dihapus${NC}"
    fi
    
    # Install NodeJS v20
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
    sudo apt-get install -y nodejs
    
    # Verify installation
    if command -v node > /dev/null 2>&1 && command -v npm > /dev/null 2>&1; then
        NODE_VERSION=$(node -v)
        NPM_VERSION=$(npm -v)
        echo -e "${GREEN}NodeJS version: $NODE_VERSION${NC}"
        echo -e "${GREEN}NPM version: $NPM_VERSION${NC}"
        echo -e "${GREEN}================== Sukses NodeJS ==================${NC}"
    else
        echo -e "${RED}NodeJS gagal diinstall. Mencoba metode alternatif...${NC}"
        # Alternative installation method
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
        sudo apt-get install -y nodejs
        echo -e "${GREEN}================== Sukses NodeJS (Alternative) ==================${NC}"
    fi
else
    NODE_VERSION=$(node -v | cut -d 'v' -f 2)
    NODE_MAJOR_VERSION=$(echo $NODE_VERSION | cut -d '.' -f 1)
    
    # Check if current version is lower than v20
    if [ "$NODE_MAJOR_VERSION" -lt 20 ]; then
        echo -e "${GREEN}============================================================================${NC}"
        echo -e "${GREEN}============== NodeJS versi ${NODE_VERSION} terdeteksi ==============${NC}"
        echo -e "${GREEN}============== Versi lebih rendah dari v20, akan diupgrade ==============${NC}"
        echo -e "${GREEN}Menghapus versi lama dan menginstall NodeJS v20...${NC}"
        
        # Remove old NodeJS
        apt-get remove -y nodejs npm
        apt-get autoremove -y
        apt-get autoclean
        
        # Remove NodeJS from different sources
        rm -rf /usr/local/bin/npm /usr/local/bin/node
        rm -rf /usr/bin/npm /usr/bin/node
        rm -rf ~/.npm
        rm -rf /usr/local/lib/node_modules
        rm -rf /usr/lib/node_modules
        
        echo -e "${GREEN}NodeJS versi lama berhasil dihapus${NC}"
        
        # Install NodeJS v20
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
        sudo apt-get install -y nodejs
        
        # Verify installation
        if command -v node > /dev/null 2>&1 && command -v npm > /dev/null 2>&1; then
            NODE_VERSION=$(node -v)
            NPM_VERSION=$(npm -v)
            echo -e "${GREEN}NodeJS version: $NODE_VERSION${NC}"
            echo -e "${GREEN}NPM version: $NPM_VERSION${NC}"
            echo -e "${GREEN}================== Sukses Upgrade NodeJS ==================${NC}"
        else
            echo -e "${RED}Upgrade NodeJS gagal. Mencoba metode alternatif...${NC}"
            # Alternative installation method
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
            sudo apt-get install -y nodejs
            echo -e "${GREEN}================== Sukses NodeJS (Alternative) ==================${NC}"
        fi
    else
        echo -e "${GREEN}============================================================================${NC}"
        echo -e "${GREEN}============== NodeJS sudah terinstall versi ${NODE_VERSION}. ==============${NC}"
        echo -e "${GREEN}========================= Lanjut install GenieACS ==========================${NC}"
    fi
fi

#MongoDB
if ! systemctl is-active --quiet mongod; then
    echo -e "${GREEN}================== Menginstall MongoDB ==================${NC}"
    
    # Function to troubleshoot MongoDB
    troubleshoot_mongodb() {
        echo -e "${GREEN}Mencoba troubleshoot MongoDB...${NC}"
        
        # Check if data directory exists and has correct permissions
        if [ ! -d "/var/lib/mongodb" ]; then
            mkdir -p /var/lib/mongodb
            chown mongodb:mongodb /var/lib/mongodb
            chmod 755 /var/lib/mongodb
        fi
        
        # Check if log directory exists
        if [ ! -d "/var/log/mongodb" ]; then
            mkdir -p /var/log/mongodb
            chown mongodb:mongodb /var/log/mongodb
        fi
        
        # Try to start MongoDB again
        systemctl start mongod
        sleep 3
        
        if systemctl is-active --quiet mongod; then
            echo -e "${GREEN}MongoDB berhasil start setelah troubleshoot${NC}"
            return 0
        else
            echo -e "${RED}MongoDB masih gagal setelah troubleshoot${NC}"
            return 1
        fi
    }
    
    # Remove any existing MongoDB repository files
    rm -f /etc/apt/sources.list.d/mongodb-org-*.list
    rm -f /etc/apt/sources.list.d/mongodb*.list
    
    # Import MongoDB GPG key using modern method
    echo -e "${GREEN}Mengimport GPG key MongoDB...${NC}"
    curl -fsSL https://pgp.mongodb.com/server-6.0.asc | \
    sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg \
    --dearmor
    
    # Add MongoDB repository for Ubuntu 22.04
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | \
    sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    
    # Update package list
    apt update
    
    # Install MongoDB
    echo -e "${GREEN}Menginstall MongoDB...${NC}"
    apt install -y mongodb-org
    
    # Check if MongoDB was installed successfully
    if command -v mongod > /dev/null 2>&1; then
        # Start and enable MongoDB
        systemctl start mongod
        systemctl enable mongod
        
        # Wait a moment for service to start
        sleep 3
        
        # Check service status
        if systemctl is-active --quiet mongod; then
            echo -e "${GREEN}MongoDB berhasil diinstall dan berjalan${NC}"
            systemctl status mongod --no-pager
            echo -e "${GREEN}================== Sukses MongoDB ==================${NC}"
        else
            echo -e "${RED}MongoDB gagal start. Mencoba troubleshoot...${NC}"
            # Try troubleshoot first
            if troubleshoot_mongodb; then
                echo -e "${GREEN}================== Sukses MongoDB (setelah troubleshoot) ==================${NC}"
            else
                echo -e "${RED}MongoDB masih gagal. Mencoba metode alternatif...${NC}"
                # Alternative: Install from Ubuntu repository
                apt remove -y mongodb-org*
                apt autoremove -y
                apt install -y mongodb
                systemctl start mongodb
                systemctl enable mongodb
                echo -e "${GREEN}================== Sukses MongoDB (Ubuntu repo) ==================${NC}"
            fi
        fi
    else
        echo -e "${RED}MongoDB gagal diinstall. Mencoba metode alternatif...${NC}"
        # Try installing from Ubuntu repository
        apt install -y mongodb
        systemctl start mongodb
        systemctl enable mongodb
        echo -e "${GREEN}================== Sukses MongoDB (Ubuntu repo) ==================${NC}"
    fi
else
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}=================== mongodb sudah terinstall sebelumnya. ===================${NC}"
fi

#GenieACS
if ! systemctl is-active --quiet genieacs-{cwmp,fs,ui,nbi}; then
    echo -e "${GREEN}================== Menginstall genieACS CWMP, FS, NBI, UI ==================${NC}"
    
    # Check if npm is available
    if command -v npm > /dev/null 2>&1; then
        npm install -g genieacs@1.2.13
    else
        echo -e "${RED}npm tidak tersedia. Mencoba install NodeJS...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
        sudo apt-get install -y nodejs
        npm install -g genieacs@1.2.13
    fi
    
    useradd --system --no-create-home --user-group genieacs || true
    mkdir -p /opt/genieacs
    mkdir -p /opt/genieacs/ext
    chown genieacs:genieacs /opt/genieacs/ext
    cat << EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret
EOF
    chown genieacs:genieacs /opt/genieacs/genieacs.env
    chown genieacs. /opt/genieacs -R
    chmod 600 /opt/genieacs/genieacs.env
    mkdir -p /var/log/genieacs
    chown genieacs. /var/log/genieacs
    # create systemd unit files
## CWMP
    cat << EOF > /etc/systemd/system/genieacs-cwmp.service
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-cwmp

[Install]
WantedBy=default.target
EOF

## NBI
    cat << EOF > /etc/systemd/system/genieacs-nbi.service
[Unit]
Description=GenieACS NBI
After=network.target
 
[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-nbi
 
[Install]
WantedBy=default.target
EOF

## FS
    cat << EOF > /etc/systemd/system/genieacs-fs.service
[Unit]
Description=GenieACS FS
After=network.target
 
[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-fs
 
[Install]
WantedBy=default.target
EOF

## UI
    cat << EOF > /etc/systemd/system/genieacs-ui.service
[Unit]
Description=GenieACS UI
After=network.target
 
[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-ui
 
[Install]
WantedBy=default.target
EOF

# config logrotate
 cat << EOF > /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}
EOF
    echo -e "${GREEN}========== Install APP GenieACS selesai... ==============${NC}"
    systemctl daemon-reload
    systemctl enable --now genieacs-{cwmp,fs,ui,nbi}
    systemctl start genieacs-{cwmp,fs,ui,nbi}    
    echo -e "${GREEN}================== Sukses genieACS CWMP, FS, NBI, UI ==================${NC}"
else
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}=================== GenieACS sudah terinstall sebelumnya. ==================${NC}"
fi

#Sukses
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
echo -e "${GREEN}=================== Informasi: Whatsapp 081947215703 =======================${NC}"
echo -e "${GREEN}============================================================================${NC}"

# Copy custom files if they exist
if [ -f "app-LU66VFYW.css" ]; then
    if [ -d "/usr/lib/node_modules/genieacs/public" ]; then
        cp -r app-LU66VFYW.css /usr/lib/node_modules/genieacs/public/
        echo -e "${GREEN}File CSS berhasil disalin${NC}"
    else
        echo -e "${RED}Folder /usr/lib/node_modules/genieacs/public tidak ditemukan${NC}"
    fi
else
    echo -e "${RED}File app-LU66VFYW.css tidak ditemukan${NC}"
fi

if [ -f "logo-3976e73d.svg" ]; then
    if [ -d "/usr/lib/node_modules/genieacs/public" ]; then
        cp -r logo-3976e73d.svg /usr/lib/node_modules/genieacs/public/
        echo -e "${GREEN}File logo berhasil disalin${NC}"
    else
        echo -e "${RED}Folder /usr/lib/node_modules/genieacs/public tidak ditemukan${NC}"
    fi
else
    echo -e "${RED}File logo-3976e73d.svg tidak ditemukan${NC}"
fi

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

# Check if mongodump is available
if command -v mongodump > /dev/null 2>&1; then
    sudo mongodump --db=genieacs --out genieacs-backup
    echo -e "${GREEN}Backup database berhasil dibuat${NC}"
else
    echo -e "${RED}mongodump tidak tersedia, skip backup${NC}"
fi

# Check if genieacs folder exists
if [ -d "genieacs" ]; then
    cd genieacs
    
    # Check if db folder exists
    if [ -d "db" ]; then
        if command -v mongorestore > /dev/null 2>&1; then
            mongorestore --db genieacs --drop ./db
            echo -e "${GREEN}Database berhasil di-restore${NC}"
        else
            echo -e "${RED}mongorestore tidak tersedia, skip restore${NC}"
        fi
    else
        echo -e "${RED}Folder db tidak ditemukan di dalam folder genieacs${NC}"
    fi
    
    cd ..
else
    echo -e "${RED}Folder genieacs tidak ditemukan${NC}"
fi

echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}=================== VIRTUAL PARAMETER BERHASIL DI INSTALL. =================${NC}"
echo -e "${GREEN}===Jika ACS URL berbeda, silahkan edit di Admin >> Provosions >> inform ====${NC}"
echo -e "${GREEN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
echo -e "${GREEN}=================== Informasi: Whatsapp 081947215703 =======================${NC}"
echo -e "${GREEN}============================================================================${NC}"

# Install aplikasi dari folder app-customer
echo -e "${GREEN}Sekarang install aplikasi customer. Apakah anda ingin melanjutkan? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${GREEN}Install aplikasi customer dibatalkan..${NC}"
    exit 1
fi

for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Lanjut Install Aplikasi Customer $i. Tekan ctrl+c untuk membatalkan"
done

# Input nama perusahaan
echo -e "${GREEN}Masukkan nama perusahaan untuk header aplikasi:${NC}"
echo -e "${GREEN}Contoh: ALIJAYA BOT MANAGEMENT ISP${NC}"
read -p "Nama Perusahaan: " company_name

# Jika kosong, gunakan default
if [ -z "$company_name" ]; then
    company_name="ALIJAYA BOT MANAGEMENT ISP"
    echo -e "${GREEN}Menggunakan nama default: $company_name${NC}"
fi

# Cek apakah folder app-customer ada
if [ -d "app-customer" ]; then
    echo -e "${GREEN}================== Menginstall Aplikasi Customer ==================${NC}"
    cd app-customer
    
    # Install dependencies
    if [ -f "package.json" ]; then
        # Check if npm is available
        if command -v npm > /dev/null 2>&1; then
            echo -e "${GREEN}Installing dependencies...${NC}"
            npm install
            echo -e "${GREEN}Dependencies berhasil diinstall${NC}"
        else
            echo -e "${RED}npm tidak tersedia. Pastikan NodeJS terinstall dengan benar.${NC}"
            echo -e "${RED}Mencoba install NodeJS...${NC}"
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
            sudo apt-get install -y nodejs
            if command -v npm > /dev/null 2>&1; then
                echo -e "${GREEN}Installing dependencies...${NC}"
                npm install
                echo -e "${GREEN}Dependencies berhasil diinstall${NC}"
            else
                echo -e "${RED}npm masih tidak tersedia. Skip install dependencies.${NC}"
            fi
        fi
        
        # Update settings.json dengan IP GenieACS dan nama perusahaan
        if [ -f "settings.json" ]; then
            echo -e "${GREEN}Mengupdate settings.json...${NC}"
            # Backup settings.json
            cp settings.json settings.json.backup
            
            # Update genieacs_url dan company_header
            if command -v jq > /dev/null 2>&1; then
                # Menggunakan jq untuk update JSON
                jq --arg url "http://$local_ip:7557" --arg company "$company_name" '.genieacs_url = $url | .company_header = $company' settings.json > settings.json.tmp && mv settings.json.tmp settings.json
            else
                # Fallback menggunakan sed jika jq tidak tersedia
                sed -i "s|\"genieacs_url\": \"[^\"]*\"|\"genieacs_url\": \"http://$local_ip:7557\"|g" settings.json
                sed -i "s|\"company_header\": \"[^\"]*\"|\"company_header\": \"$company_name\"|g" settings.json
            fi
            echo -e "${GREEN}GenieACS URL berhasil diupdate: http://$local_ip:7557${NC}"
            echo -e "${GREEN}Nama perusahaan berhasil diupdate: $company_name${NC}"
        else
            echo -e "${RED}settings.json tidak ditemukan di folder app-customer${NC}"
        fi
        
        # Baca pengaturan dari settings.json
        PORT=3001  # Default port
        if [ -f "settings.json" ]; then
            echo -e "${GREEN}Membaca pengaturan dari settings.json...${NC}"
            # Extract port dari settings.json menggunakan jq atau sed
            if command -v jq > /dev/null 2>&1; then
                PORT=$(jq -r '.server_port // 3001' settings.json)
            else
                # Fallback menggunakan sed jika jq tidak tersedia
                PORT=$(grep -o '"server_port"[[:space:]]*:[[:space:]]*[0-9]*' settings.json | sed 's/.*:[[:space:]]*//' || echo "3001")
            fi
            echo -e "${GREEN}Port yang digunakan: $PORT${NC}"
        else
            echo -e "${GREEN}settings.json tidak ditemukan, menggunakan port default: $PORT${NC}"
        fi
        
        # Buat systemd service untuk auto-restart
        cat << EOF > /etc/systemd/system/app-customer.service
[Unit]
Description=App Customer Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=$PORT

[Install]
WantedBy=multi-user.target
EOF
        
        # Reload systemd dan enable service
        systemctl daemon-reload
        systemctl enable app-customer.service
        systemctl start app-customer.service
        
        echo -e "${GREEN}Service app-customer berhasil dibuat dan dijalankan${NC}"
        echo -e "${GREEN}Status service: $(systemctl is-active app-customer.service)${NC}"
        echo -e "${GREEN}App Customer berjalan di port: $PORT${NC}"
        echo -e "${GREEN}Akses: http://$local_ip:$PORT${NC}"
        echo -e "${GREEN}GenieACS URL: http://$local_ip:7557${NC}"
    else
        echo -e "${RED}package.json tidak ditemukan di folder app-customer${NC}"
    fi
    
    cd ..
    echo -e "${GREEN}================== Sukses Install Aplikasi Customer ==================${NC}"
else
    echo -e "${RED}Folder app-customer tidak ditemukan.${NC}"
fi

echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}=================== INSTALASI SELESAI =================${NC}"
echo -e "${GREEN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
echo -e "${GREEN}=================== Informasi: Whatsapp 081947215703 =======================${NC}"
echo -e "${GREEN}============================================================================${NC}"

# Status check
echo -e "${GREEN}=================== STATUS INSTALASI =================${NC}"
echo -e "${GREEN}Mengecek status instalasi...${NC}"

# Check NodeJS
if command -v node > /dev/null 2>&1; then
    echo -e "${GREEN}✓ NodeJS: $(node -v)${NC}"
else
    echo -e "${RED}✗ NodeJS: Tidak terinstall${NC}"
fi

# Check NPM
if command -v npm > /dev/null 2>&1; then
    echo -e "${GREEN}✓ NPM: $(npm -v)${NC}"
else
    echo -e "${RED}✗ NPM: Tidak terinstall${NC}"
fi

# Check MongoDB
if command -v mongod > /dev/null 2>&1; then
    echo -e "${GREEN}✓ MongoDB: Terinstall${NC}"
    if systemctl is-active --quiet mongod; then
        echo -e "${GREEN}✓ MongoDB Service: Aktif${NC}"
    else
        echo -e "${RED}✗ MongoDB Service: Tidak aktif${NC}"
    fi
else
    echo -e "${RED}✗ MongoDB: Tidak terinstall${NC}"
fi

# Check GenieACS services
services=("genieacs-cwmp" "genieacs-fs" "genieacs-ui" "genieacs-nbi")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo -e "${GREEN}✓ $service: Aktif${NC}"
    else
        echo -e "${RED}✗ $service: Tidak aktif${NC}"
    fi
done

# Check app-customer service
if systemctl is-active --quiet app-customer; then
    echo -e "${GREEN}✓ app-customer: Aktif${NC}"
else
    echo -e "${RED}✗ app-customer: Tidak aktif${NC}"
fi

echo -e "${GREEN}=================== END STATUS =================${NC}"

