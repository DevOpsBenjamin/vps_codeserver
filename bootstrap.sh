#!/bin/bash
# bootstrap.sh - Installation complète en une commande

set -e

echo "🚀 VPS CodeServer Bootstrap"
echo "=========================="

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Installation Docker si nécessaire
install_docker() {
    if command -v docker &> /dev/null; then
        log_info "Docker already installed"
        return
    fi
    
    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    
    log_warn "Docker installed. Please logout/login and run this script again."
    exit 0
}

# 2. Clone des repositories
clone_repos() {
    log_info "Cloning repositories..."
    
    # Repository principal (public)
    if [ ! -d "vps-codeserver" ]; then
        git clone https://github.com/yourusername/vps-codeserver.git
    fi
    
    cd vps-codeserver
    
    # Repository secrets (privé) - avec gestion d'erreur
    if [ ! -d "secrets" ]; then
        log_info "Cloning private secrets..."
        if git clone git@github.com:yourusername/vps-secrets.git secrets; then
            log_info "✅ Private secrets loaded"
        else
            log_warn "❌ Cannot access private secrets, creating local setup"
            setup_local_secrets
        fi
    fi
}

# 3. Setup secrets locaux si pas d'accès au repo privé
setup_local_secrets() {
    log_info "Setting up local secrets directory..."
    mkdir -p secrets/{ssh-keys,configs,backups}
    
    # Copie des templates
    cp templates/.env.example secrets/.env
    cp templates/ssh-config.example secrets/configs/ssh-config
    
    log_warn "🔐 Please configure your secrets:"
    log_warn "   - Edit secrets/.env"
    log_warn "   - Add SSH keys to secrets/ssh-keys/"
    log_warn "   - Configure secrets/configs/"
    
    read -p "Press Enter when secrets are configured..."
}

# 4. Validation des secrets
validate_secrets() {
    log_info "Validating secrets configuration..."
    
    if [ ! -f "secrets/.env" ]; then
        log_error "secrets/.env not found"
        exit 1
    fi
    
    source secrets/.env
    
    if [ -z "$PASSWORD" ]; then
        log_error "PASSWORD not set in secrets/.env"
        exit 1
    fi
    
    if [ ! -d "secrets/ssh-keys" ] || [ -z "$(ls -A secrets/ssh-keys 2>/dev/null)" ]; then
        log_warn "No SSH keys found in secrets/ssh-keys/"
    fi
    
    log_info "✅ Secrets validation passed"
}

# 5. Build et lancement
deploy() {
    log_info "Building and deploying CodeServer..."
    
    # Build de l'image
    docker build -t vps-codeserver .
    
    # Arrêt du container existant si présent
    if docker ps -a --format '{{.Names}}' | grep -q '^codeserver-main$'; then
        log_info "Stopping existing container..."
        docker rm -f codeserver-main
    fi
    
    # Lancement avec docker-compose
    docker-compose up -d
    
    log_info "✅ CodeServer deployed successfully!"
    
    # Attendre que le service soit prêt
    log_info "Waiting for service to be ready..."
    sleep 10
    
    if curl -s http://localhost:8080 > /dev/null; then
        log_info "🌐 CodeServer is accessible at: http://$(curl -s ifconfig.me):8080"
    else
        log_warn "Service might still be starting..."
    fi
}

# 6. Setup du backup automatique
setup_backup() {
    log_info "Setting up automatic backup..."
    
    # Script de backup
    cat > secrets/backup.sh << 'EOF'
#!/bin/bash
# Auto-backup des secrets vers git

cd "$(dirname "$0")"

# Backup des configs Docker
docker exec codeserver-main bash -c "tar -czf /tmp/workspace-backup.tar.gz -C /workspace ."
docker cp codeserver-main:/tmp/workspace-backup.tar.gz backups/workspace-$(date +%Y%m%d).tar.gz

# Commit et push des secrets
git add .
git commit -m "Backup $(date '+%Y-%m-%d %H:%M:%S')" || true
git push origin main || true

echo "✅ Backup completed"
EOF
    
    chmod +x secrets/backup.sh
    
    # Cron job pour backup quotidien
    (crontab -l 2>/dev/null; echo "0 2 * * * $(pwd)/secrets/backup.sh") | crontab -
    
    log_info "✅ Daily backup configured (2:00 AM)"
}

# 7. Restoration depuis backup
restore_from_backup() {
    if [ "$1" == "--restore" ]; then
        log_info "🔄 Restoring from backup..."
        
        if [ -f "secrets/backups/workspace-$(date +%Y%m%d).tar.gz" ]; then
            log_info "Restoring workspace..."
            tar -xzf "secrets/backups/workspace-$(date +%Y%m%d).tar.gz" -C volumes/workspace/
        fi
        
        log_info "✅ Restoration completed"
    fi
}

# Menu principal
main() {
    case "${1:-install}" in
        "install")
            install_docker
            clone_repos
            validate_secrets
            deploy
            setup_backup
            ;;
        "restore")
            clone_repos
            restore_from_backup --restore
            validate_secrets
            deploy
            ;;
        "backup")
            if [ -d "secrets" ]; then
                cd secrets && ./backup.sh
            else
                log_error "No secrets directory found"
                exit 1
            fi
            ;;
        "update")
            git pull
            cd secrets && git pull
            docker-compose down
            docker build --no-cache -t vps-codeserver .
            docker-compose up -d
            ;;
        *)
            echo "Usage: $0 [install|restore|backup|update]"
            echo "  install - Fresh installation"
            echo "  restore - Restore from backup"
            echo "  backup  - Manual backup"
            echo "  update  - Update and restart"
            ;;
    esac
}

main "$@"
