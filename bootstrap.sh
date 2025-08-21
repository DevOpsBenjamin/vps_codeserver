
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
    # Extract repo URL from the script URL
    # If script is from: https://raw.githubusercontent.com/USER/REPO/main/bootstrap.sh
    # Then repo is: https://github.com/USER/REPO
    local script_url="${BASH_SOURCE[1]}"
    
    log_info "📥 Url: [$REPO_URL]"
}


# Main execution
main() {
    install_docker
    clone_repo
    log_info "🎉 Your VPS is setup for code server"
}

main "$@"
