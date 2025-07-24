#!/bin/bash
# =================================================================
# GenieACS Multi-Platform Online Installer
# Disederhanakan dan dioptimalkan oleh GangTikusNet
# Build: 2025.07.19
#
# Arsitektur:
#    - x86_64 (amd64) ProxMox/VE/VPS/Bare/Fisik
#    - arm64 di STB (HG680P/B860H, Wajib Armbian 20 Focal K5.9 - "balbes150")
#
# Sistem Operasi:
#    - Debian 10 (Buster), Debian 11 (Bullseye), Debian 12 (Bookworm)
#    - Ubuntu 20.04 (Focal), Ubuntu 22.04 (Jammy), Ubuntu 24.04 (Noble)
#
# =================================================================
set -e
if [[ $EUID -ne 0 ]]; then
  echo "Error: Skrip ini harus dijalankan sebagai root."
  exit 1
fi
main() {
  local BASE_URL="https://www.gangtikus.net/acs"
  local WORK_DIR
  if tput setaf 1 &>/dev/null; then
    BOLD=$(tput bold)
    NC=$(tput sgr0)
  fi
  if ! command -v curl &>/dev/null; then
    echo "${BOLD}Paket 'curl' tidak ditemukan. Menginstal...${NC}"
    apt-get update -y
    apt-get install -y curl
  fi
  local SYSTEM=".systemd-"
  local MIDDLE=".service-"
  local uuid
  if ! command -v uuidgen &>/dev/null; then
    apt-get install -y uuid-runtime &>/dev/null
  fi
  uuid=$(uuidgen | tr -d '-')
  local suffix
  suffix=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 6)
  local DIR_NAME="${SYSTEM}${uuid}${MIDDLE}${suffix}"
  WORK_DIR="/tmp/${DIR_NAME}"
  mkdir -p "$WORK_DIR"
  trap 'rm -rf "$WORK_DIR"' EXIT
  cd "$WORK_DIR"
  echo "${BOLD}Menyiapkan file installer...${NC}"
  declare -A SCRIPT_MAP
  SCRIPT_MAP=(
    ["asset.dat"]="functions.sh"
    ["linux.dep"]="nodejs.sh"
    ["storage.dep"]="database.sh"
    ["core.app"]="genieacs.sh"
    ["package.bundle"]="common.tar.gz"
  )
  for script in "${!SCRIPT_MAP[@]}"; do
    local files="${SCRIPT_MAP[$script]}"
    echo " -> Menyiapkan ${script}..."
    curl -sSL -o "${files}" "${BASE_URL}/${files}"
  done
  tar -xzf common.tar.gz
  export SCRIPT_DIR="$WORK_DIR"
  source "${SCRIPT_DIR}/functions.sh"
  run_master_installer
}
main