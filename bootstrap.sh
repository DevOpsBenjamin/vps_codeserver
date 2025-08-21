#!/bin/bash
# bootstrap.sh - Step 1: Just Docker

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🚀 Bootstrap Step 1: Docker"

# Install Docker if needed
install_docker() {
    if command -v docker &> /dev/null; then
        log_info "✅ Docker already installed"
        if docker ps >/dev/null 2>&1; then
            log_info "✅ Docker is working"
        else
            log_error "❌ Docker installed but not working (permissions?)"
            return 1
        fi
        return
    fi
    
    log_info "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    log_info "✅ Docker installed"
    
    # Test Docker
    if docker ps >/dev/null 2>&1; then
        log_info "✅ Docker is working immediately"
    else
        log_info "🔄 Docker needs group activation..."
        log_info "💡 Restarting script with proper permissions..."
        exec sg docker "$0 $*"
    fi
}

# Main execution
main() {
    install_docker
    log_info "🎉 Step 1 completed - Docker is ready!"
}

main "$@"
