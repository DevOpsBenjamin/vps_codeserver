#!/bin/bash
# bootstrap.sh - Simple one-command VPS setup

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
REPO_URL="https://github.com/DevOpsBenjamin/vps_codeserver"
echo "🚀 VPS CodeServer Bootstrap"
echo "=========================="

# Install Docker if needed
install_docker() {
    if command -v docker &> /dev/null; then
        log_info "✅ Docker already installed"
        return
    fi
    
    log_info "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    
    log_warn "🔄 Docker installed. Please logout and login again, then run:"
    log_warn "   curl -fsSL $REPO_URL/raw/main/bootstrap.sh | bash"
    exit 0
}

# Clone repository
clone_repo() {
    log_info "📥 Cloning repository..."
    
    if [ -d "vps-codeserver" ]; then
        cd vps-codeserver
        git pull
    else
        git clone $REPO_URL
        cd vps-codeserver
    fi
}

# Setup configuration
setup_config() {
    log_info "⚙️  Setting up configuration..."
    
    # Create secrets directory
    mkdir -p secrets/ssh-keys
    
    # Create .env if it doesn't exist
    if [ ! -f "secrets/.env" ]; then
        # Generate random password
        RANDOM_PASSWORD=$(openssl rand -base64 32 | tr -d /=+ | cut -c1-20)
        
        cat > secrets/.env << EOF
# VPS CodeServer Configuration
PASSWORD=$RANDOM_PASSWORD
EXTERNAL_PORT=8080
OLLAMA_BASE_URL=http://localhost:11434
GIT_USER_NAME=CodeServer User
GIT_USER_EMAIL=user@codeserver.local
EOF
        
        log_info "🔑 Generated random password: $RANDOM_PASSWORD"
        log_warn "💡 You can change it in secrets/.env"
    else
        log_info "✅ Configuration already exists"
    fi
}

# Deploy
deploy() {
    log_info "🚀 Deploying CodeServer..."
    
    # Make scripts executable
    chmod +x scripts/*.sh
    
    # Build and start
    ./scripts/utils.sh build
    ./scripts/utils.sh start
    
    log_info "✅ Deployment completed!"
}

# Main execution
main() {
    install_docker
    clone_repo
    setup_config
    deploy
    
    echo
    log_info "🎉 VPS CodeServer is ready!"
    log_info "🌐 Access your CodeServer at: http://$(curl -s ifconfig.me):8080"
    log_info "🔑 Password is in: secrets/.env"
    echo
    log_info "💡 Next steps:"
    log_info "   1. Setup SSH tunnel from home PC for Ollama"
    log_info "   2. Install Claude Code when available"
    log_info "   3. Start coding!"
    echo
    log_info "📚 Management commands:"
    log_info "   ./scripts/utils.sh status   - Check status"
    log_info "   ./scripts/utils.sh logs     - View logs"
    log_info "   ./scripts/utils.sh shell    - Open shell"
}

main "$@"
