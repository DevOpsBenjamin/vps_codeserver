# 🔐 Secrets Management avec Doppler

Ce guide explique comment configurer Doppler pour synchroniser vos secrets entre VPS.

## 🚀 Setup initial (à faire une seule fois)

### 1. Créer compte Doppler
- Aller sur https://dashboard.doppler.com
- Créer un compte gratuit
- Créer un projet `vps_codeserver`

### 2. Configuration locale
```bash
# Après votre première installation
cd vps-codeserver
./scripts/secrets-doppler.sh setup
./scripts/secrets-doppler.sh upload
./scripts/secrets-doppler.sh token
```

### 3. Sauvegarder le token
La commande `token` vous donnera quelque chose comme :
```
DOPPLER_TOKEN=dp.st.production.abcd1234...
```

**Sauvegardez ce token** dans vos notes/password manager !

## 🎯 Déploiement automatique

### Installation avec Doppler
```bash
# Sur n'importe quel nouveau VPS
export DOPPLER_TOKEN=dp.st.production.abcd1234...
curl -fsSL https://raw.githubusercontent.com/DevOpsBenjamin/vps_codeserver/main/bootstrap.sh | bash
```

Vos secrets seront automatiquement téléchargés et configurés !

## 📋 Secrets requis dans Doppler

Assurez-vous d'avoir ces variables dans votre projet Doppler :

### Variables principales
```bash
PASSWORD=your-secure-password
EXTERNAL_PORT=8080
OLLAMA_BASE_URL=http://localhost:11434
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=your@email.com
```

### SSH Keys (optionnels)
- `SSH_PRIVATE_KEY` : Votre clé privée SSH (base64)
- `SSH_PUBLIC_KEY` : Votre clé publique SSH (base64)

## 🔧 Gestion quotidienne

### Modifier des secrets
1. **Via web** : https://dashboard.doppler.com/workplace/vps-codeserver/production
2. **Via CLI** :
```bash
./scripts/secrets-doppler.sh upload  # Upload modifications locales
./scripts/secrets-doppler.sh download  # Download modifications distantes
```

### Redémarrer après changement
```bash
./scripts/utils.sh restart
```

## 🆘 Troubleshooting

### Erreur "Doppler token invalid"
```bash
# Regénérer un token
./scripts/secrets-doppler.sh token
```

### Secrets pas synchronisés
```bash
# Vérifier les secrets
./scripts/secrets-doppler.sh download
cat secrets/.env
```

### Problème d'authentification
```bash
# Re-login
./scripts/secrets-doppler.sh setup
```

## 🔄 Migration depuis setup existant

Si vous avez déjà un VPS configuré :

```bash
# Upload votre config actuelle vers Doppler
./scripts/secrets-doppler.sh setup
./scripts/secrets-doppler.sh upload

# Obtenir le token pour futurs déploiements
./scripts/secrets-doppler.sh token
```

## 💡 Bonnes pratiques

- **Un projet Doppler** = un environnement (production)
- **Gardez le token secret** et sécurisé
- **Utilisez différents tokens** pour différents environnements
- **Régénérez les tokens** périodiquement

## 🌐 Interface Web

Dashboard Doppler : https://dashboard.doppler.com/workplace/vps-codeserver/production

Vous pouvez :
- ✅ Voir tous vos secrets
- ✅ Modifier les valeurs
- ✅ Voir l'historique des changements
- ✅ Gérer les tokens d'accès
- ✅ Inviter des collaborateurs
