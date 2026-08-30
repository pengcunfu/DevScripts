#!/bin/bash
# ============================================
# Common utilities for mirror config scripts
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${CYAN}[SUCCESS]${NC} $1"; }

backup_sources() {
    local source_file=$1
    if [ -f "$source_file" ]; then
        local backup_file="${source_file}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$source_file" "$backup_file"
        info "已备份: $backup_file"
    fi
}
