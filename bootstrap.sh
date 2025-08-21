#!/bin/bash
# bootstrap.sh - Step 1: Just Docker
REPO_SSH_URL='git@github.com:DevOpsBenjamin/vps_codeserver.git'
REPO_HTTPS_URL='https://github.com/DevOpsBenjamin/vps_codeserver.git'
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
    if [ -d "vps_codeserver" ]; then
        log_info "📥 Repo already present pulling..."
        cd vps_codeserver
        git pull
    else
        log_info "📥 Cloning [$REPO_HTTPS_URL]..."
        git clone "$REPO_HTTPS_URL"
        cd vps_codeserver
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
      
    # Install Doppler CLI if needed
    if ! command -v doppler &> /dev/null; then
        log_info "📦 Installing Doppler CLI..."
        curl -Ls --tlsv1.2 --proto "=https" --retry 3 https://cli.doppler.com/install.sh | sudo sh
    else
        log_info "✅ Doppler already installed"
    fi
}

get_secret() {
    # Required secrets list
    local required_secrets=("CODESERVER_PASSWORD" "SSH_PRIVATE_KEY" "SSH_PUBLIC_KEY")
    local missing_secrets=()
    
    log_info "🔍 Checking required secrets in Doppler..."
    
    # Check if all required secrets exist
    for secret in "${required_secrets[@]}"; do
        if ! doppler secrets get "$secret" --plain >/dev/null 2>&1; then
            missing_secrets+=("$secret")
        fi
    done
    
    # Exit if any secrets are missing
    if [ ${#missing_secrets[@]} -ne 0 ]; then
        log_error "❌ Missing required secrets in Doppler:"
        for secret in "${missing_secrets[@]}"; do
            log_error "   - $secret"
        done
        log_error "Please add these secrets to your Doppler project and try again."
        exit 1
    fi
    
    log_info "✅ All required secrets found in Doppler"    
    # Download secrets
    log_info "🔽 Downloading secrets from Doppler..."

    # Create .env file with required secrets
    cat > .env << EOF
# VPS CodeServer Configuration (from Doppler)
PASSWORD='$(doppler secrets get CODESERVER_PASSWORD --plain)'
EXTERNAL_PORT=8080
OLLAMA_BASE_URL=http://localhost:11434
GIT_USER_NAME=vscode
GIT_USER_EMAIL=vscode@codeserver.local
EOF
    log_info "✅ Environment secrets downloaded"

    # Download SSH keys
    mkdir -p .ssh
    doppler secrets get SSH_PRIVATE_KEY --plain > .ssh/id_rsa
    chmod 600 .ssh/id_rsa
    log_info "✅ SSH private key downloaded"
    
    doppler secrets get SSH_PUBLIC_KEY --plain > .ssh/id_rsa.pub
    chmod 644 .ssh/id_rsa.pub
    log_info "✅ SSH public key downloaded"
    
    # Switch git remote to SSH now that we have keys
    log_info "🔄 Switching git remote to SSH..."
    git remote set-url origin "$REPO_SSH_URL"
    
    log_info "✅ Doppler setup completed"
}

#Docker compose and run
build_and_deploy() {
    log_info "🔨 Building Docker image..."
    chmod +x scripts/utils.sh
    ./scripts/utils.sh build
    
    log_info "🚀 Starting CodeServer..."
    ./scripts/utils.sh start
}

# Main execution
main() {
    install_docker
    clone_repo
    setup_doppler
    get_secret
    build_and_deploy
    log_info "🎉 Your VPS is setup for code server"
}

main "$@"
