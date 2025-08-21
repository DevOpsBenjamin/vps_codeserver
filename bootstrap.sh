#!/bin/bash
# bootstrap.sh - Step 1: Just Docker
REPO_URL=https://github.com/DevOpsBenjamin/vps_codeserver
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "🚀 Bootstrap Setting up VPS"

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

# Clone repository
clone_repo() {
    log_info "📥 Cloning [$REPO_URL..."
    
    if [ -d "vps_codeserver" ]; then
        cd vps_codeserver && git pull
    else
        git clone "$REPO_URL" && cd vps_codeserver
    fi
}

# Setup Doppler
setup_doppler() {
    # Skip if no DOPPLER_TOKEN
    if [ -z "${DOPPLER_TOKEN:-}" ]; then
        log_error "⚠️  No DOPPLER_TOKEN found. Do export of the token and run the setup again."
        log_info "export DOPPLER_TOKEN=dp.st.xxx"
        exit 0
    fi
    
    log_info "🔐 Setting up Doppler secrets..."    
    # Install Doppler CLI if needed
    if ! command -v doppler &> /dev/null; then
        log_info "📦 Installing Doppler CLI..."
        curl -Ls --tlsv1.2 --proto "=https" --retry 3 https://cli.doppler.com/install.sh | sudo sh
    fi
}

get_secret() {
    # Download secrets
    log_info "🔽 Downloading secrets from Doppler..."
    mkdir -p secrets/ssh-keys
    
    # Download .env file
    if doppler secrets download --format env --no-file > secrets/.env 2>/dev/null; then
        log_info "✅ Environment secrets downloaded"
    else
        log_error "❌ Failed to download secrets from Doppler"
        return 1
    fi
    
    # Download SSH keys if they exist
    if doppler secrets get SSH_PRIVATE_KEY --plain >/dev/null 2>&1; then
        doppler secrets get SSH_PRIVATE_KEY --plain | base64 -d > secrets/ssh-keys/id_rsa
        chmod 600 secrets/ssh-keys/id_rsa
        log_info "✅ SSH private key downloaded"
    fi
    
    if doppler secrets get SSH_PUBLIC_KEY --plain >/dev/null 2>&1; then
        doppler secrets get SSH_PUBLIC_KEY --plain | base64 -d > secrets/ssh-keys/id_rsa.pub
        chmod 644 secrets/ssh-keys/id_rsa.pub
        log_info "✅ SSH public key downloaded"
    fi
    
    log_info "✅ Doppler setup completed"
}

# Main execution
main() {
    install_docker
    clone_repo
    setup_doppler
    log_info "🎉 Your VPS is setup for code server"
}

main "$@"
