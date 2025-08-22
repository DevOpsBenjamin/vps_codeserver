# 🚀 VPS CodeServer

Ce dépôt permet de déployer automatiquement un environnement [code-server](https://github.com/coder/code-server) sur un VPS grâce à Docker, Doppler et Caddy. En deux commandes, votre machine est prête pour coder à distance.

## ⚡ Installation express

1. Générez un token pour votre projet sur [Doppler](https://doppler.com) contenant les secrets requis.
2. Sur votre VPS fraîchement installé :

```bash
export DOPPLER_TOKEN=dp.st.prd.VOTRE_TOKEN
curl -fsSL "https://raw.githubusercontent.com/DevOpsBenjamin/vps_codeserver/main/bootstrap.sh" | bash
```

Le script `bootstrap.sh` :
- installe Docker si nécessaire ;
- clone ce dépôt ;
- télécharge les secrets depuis Doppler et génère `.env` et les clés SSH ;
- construit l'image Docker et lance `docker compose` (CodeServer + Caddy).

## 🔑 Secrets Doppler

Le projet Doppler doit contenir au minimum :

| Clé                | Description                                               |
|--------------------|-----------------------------------------------------------|
| `CODESERVER_PASSWORD` | Mot de passe pour l'accès à code-server                 |
| `SSH_PRIVATE_KEY`  | Clé privée SSH (PEM) utilisée pour `git`                   |
| `SSH_PUBLIC_KEY`   | Clé publique correspondante                               |

Variables optionnelles prises en compte dans `.env` :

| Clé             | Valeur par défaut            |
|-----------------|------------------------------|
| `EXTERNAL_PORT` | `8080`                        |
| `OLLAMA_BASE_URL` | `http://localhost:11434`   |
| `GIT_USER_NAME`   | `vscode`                    |
| `GIT_USER_EMAIL`  | `vscode@codeserver.local`   |

## 🛠️ Gestion quotidienne

Tout est piloté via `scripts/utils.sh` :

```bash
./scripts/utils.sh build       # construire l'image
./scripts/utils.sh start       # démarrer CodeServer et Caddy
./scripts/utils.sh stop        # arrêter les conteneurs
./scripts/utils.sh status      # afficher l'état et l'IP publique
./scripts/utils.sh logs        # suivre les logs
```

## 🍴 Utiliser votre propre fork

1. **Forker** ce dépôt sur votre compte GitHub.
2. Adapter le `Caddyfile` à votre domaine (remplacer `jetdail.fr`, etc.), puis committer.
3. Modifier les variables `REPO_HTTPS_URL` et `REPO_SSH_URL` en haut de `bootstrap.sh` pour pointer vers votre fork.
4. Créer un projet Doppler et y ajouter vos secrets.
5. Lancer l'installation en remplaçant l'URL du `curl` par celle de votre fork :

```bash
export DOPPLER_TOKEN=dp.st.prd.VOTRE_TOKEN
curl -fsSL "https://raw.githubusercontent.com/<votre-user>/vps_codeserver/main/bootstrap.sh" | bash
```

## 📁 Structure

- `bootstrap.sh` – configuration initiale (Docker, Doppler, build, démarrage)
- `docker-compose.yml` – services `codeserver` et `caddy`
- `Dockerfile` – image CodeServer personnalisée
- `scripts/utils.sh` – utilitaires de gestion
- `Caddyfile` – configuration du reverse proxy
- `workspace/` & `vscode-config/` – volumes persistants

## 🔒 Sécurité

- Le fichier `.env` est généré automatiquement depuis Doppler et ne doit pas être commit.
- Les clés SSH sont stockées dans `.ssh/` avec les permissions correctes.
- Conservez votre `DOPPLER_TOKEN` et vos secrets en lieu sûr.

## 🤝 Contribution

Les contributions sont les bienvenues ! Forkez, créez une branche (ou travaillez sur `main`) et soumettez une Pull Request.
