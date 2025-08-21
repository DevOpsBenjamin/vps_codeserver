#!/bin/bash
# utils.sh - Simple management script for VPS CodeServer

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if .env exists
check_env() {
    if [ ! -f ".env" ]; then
        log_error "No .env file found. Create .env first."
        exit 1
    fi
}

# Build Docker image
build() {
    log_info "🔨 Building CodeServer image..."
    docker build -t vps-codeserver .
    log_info "✅ Build completed"
}

# Start services
start() {
    check_env
    log_info "🚀 Starting CodeServer..."
    
    # Create volumes if they don't exist
    mkdir -p {workspace,vscode-config}
    
    # Start with docker compose
    docker compose up -d
    
    # Wait a bit for startup
    sleep 5
    
    # Check if running
    if docker ps | grep -q codeserver-main; then
        log_info "✅ CodeServer started successfully"
        
        # Get external IPv4 (force IPv4 with multiple fallbacks)
        EXTERNAL_IP=$(curl -4 -s ifconfig.me 2>/dev/null || \
                     curl -4 -s ipv4.icanhazip.com 2>/dev/null || \
                     curl -4 -s api.ipify.org 2>/dev/null || \
                     echo "your-server-ip")
        
        EXTERNAL_PORT=$(grep EXTERNAL_PORT .env 2>/dev/null | cut -d'=' -f2 || echo "8080")
        
        log_info "🌐 Access at: http://$EXTERNAL_IP:$EXTERNAL_PORT"
        log_info "🔑 Password: check your .env file"
    else
        log_error "❌ Failed to start CodeServer"
        docker compose logs
    fi
}

# Stop services
stop() {
    log_info "⏹️  Stopping CodeServer..."
    docker compose down
    log_info "✅ Stopped"
}

# Restart services
restart() {
    stop
    start
}

# Rebuild and restart
rebuild() {
    log_info "🔄 Rebuilding and restarting..."
    stop
    build
    start
}

# Show logs
logs() {
    docker compose logs -f
}

# Open shell in container
shell() {
    if docker ps | grep -q codeserver-main; then
        log_info "🐚 Opening shell in CodeServer container..."
        docker exec -it codeserver-main /bin/bash
    else
        log_error "Container not running. Start it first: ./scripts/utils.sh start"
    fi
}

# Show status
status() {
    log_info "📊 CodeServer Status:"
    
    if docker ps | grep -q codeserver-main; then
        log_info "✅ Running"
        docker compose ps
        
        # Show resource usage
        echo
        log_info "Resource Usage:"
        docker stats codeserver-main --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    else
        log_warn "❌ Not running"
        docker compose ps
    fi
}

# Update everything
update() {
    log_info "⬆️  Updating CodeServer..."
    
    # Pull latest code
    git pull
    
    # Pull secrets if it's a git repo
    if [ -d "secrets/.git" ]; then
        cd secrets && git pull && cd ..
    fi
    
    # Rebuild and restart
    rebuild
    
    log_info "✅ Update completed"
}

# Clean up
clean() {
    log_info "🧹 Cleaning up..."
    docker compose down
    docker system prune -f
    log_info "✅ Cleanup completed"
}

# Install Claude Code manually (when available)
install_claude() {
    if docker ps | grep -q codeserver-main; then
        log_info "📦 Installing Claude Code in container..."
        docker exec codeserver-main npm install -g @anthropic-ai/claude-code || log_warn "Claude Code not available yet"
    else
        log_error "Container not running"
    fi
}

# Test Ollama connection
test_ollama() {
    if docker ps | grep -q codeserver-main; then
        log_info "🧪 Testing Ollama connection..."
        if docker exec codeserver-main curl -s http://localhost:11434/api/tags >/dev/null; then
            log_info "✅ Ollama is accessible from container"
        else
            log_warn "❌ Cannot reach Ollama. Is the tunnel running from home?"
        fi
    else
        log_error "Container not running"
    fi
}

# Help
help() {
    echo "VPS CodeServer Management"
    echo "========================"
    echo
    echo "Usage: $0 <command>"
    echo
    echo "Commands:"
    echo "  build         - Build Docker image"
    echo "  start         - Start CodeServer"
    echo "  stop          - Stop CodeServer"
    echo "  restart       - Restart CodeServer"
    echo "  rebuild       - Rebuild and restart"
    echo "  logs          - Show logs"
    echo "  shell         - Open shell in container"
    echo "  status        - Show status and resource usage"
    echo "  update        - Update and restart"
    echo "  clean         - Clean up containers and images"
    echo "  install-claude- Install Claude Code manually"
    echo "  test-ollama   - Test Ollama tunnel connection"
    echo "  help          - Show this help"
}

# Main command handler
case "${1:-help}" in
    build) build ;;
    start) start ;;
    stop) stop ;;
    restart) restart ;;
    rebuild) rebuild ;;
    logs) logs ;;
    shell) shell ;;
    status) status ;;
    update) update ;;
    clean) clean ;;
    install-claude) install_claude ;;
    test-ollama) test_ollama ;;
    help|*) help ;;
esac
