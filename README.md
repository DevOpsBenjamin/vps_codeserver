# 🚀 VPS CodeServer

This repository automates the deployment of a [code-server](https://github.com/coder/code-server) environment on a VPS using Docker, Doppler and Caddy. In just a couple of commands your server is ready for remote coding.

## ⚡ Quick install

1. Generate a token in [Doppler](https://doppler.com) containing the required secrets.
2. On your freshly installed VPS run:

```bash
export DOPPLER_TOKEN=dp.st.prd.YOUR_TOKEN
curl -fsSL "https://raw.githubusercontent.com/DevOpsBenjamin/vps_codeserver/main/bootstrap.sh" | bash
```

You can execute the command from any directory (e.g. `/work`). The script creates two folders: `vps_codeserver/` for this repository and `git/` for your own repositories. The `git/` folder is mounted inside CodeServer at `/workspace/git` so you can manage additional Git projects easily.

The `bootstrap.sh` script:

- installs Docker if necessary
- clones this repository
- downloads secrets from Doppler to generate `.env` and SSH keys
- builds the Docker image and starts `docker compose` (CodeServer + Caddy)

## 🔑 Doppler secrets

Your Doppler project must contain at least:

| Key | Description |
| --- | --- |
| `CODESERVER_PASSWORD` | Password for access to code-server |
| `SSH_PRIVATE_KEY` | SSH private key (PEM) used for `git` |
| `SSH_PUBLIC_KEY` | Matching public key |

Optional variables recognized in `.env`:

| Key | Default value |
| --- | --- |
| `EXTERNAL_PORT` | `8080` |
| `OLLAMA_BASE_URL` | `http://localhost:11434` |
| `GIT_USER_NAME` | `vscode` |
| `GIT_USER_EMAIL` | `vscode@codeserver.local` |

## 🛠️ Daily usage

Everything is controlled via `scripts/utils.sh`:

```bash
./scripts/utils.sh build   # build the image
./scripts/utils.sh start   # start CodeServer and Caddy
./scripts/utils.sh stop    # stop the containers
./scripts/utils.sh status  # display status and public IP
./scripts/utils.sh logs    # follow logs
```

## 🍴 Use your own fork

1. **Fork** this repository on GitHub.
2. Adjust the `Caddyfile` for your domain (replace `jetdail.fr`, etc.) and commit.
3. Modify `REPO_HTTPS_URL` and `REPO_SSH_URL` at the top of `bootstrap.sh` to point to your fork.
4. Create a Doppler project and add your secrets.
5. Launch the installation using your fork's bootstrap script:

```bash
export DOPPLER_TOKEN=dp.st.prd.YOUR_TOKEN
curl -fsSL "https://raw.githubusercontent.com/<your-user>/vps_codeserver/main/bootstrap.sh" | bash
```

## 📁 Structure

- `bootstrap.sh` – initial setup (Docker, Doppler, build, start)
- `docker-compose.yml` – services `codeserver` and `caddy`
- `Dockerfile` – custom CodeServer image
- `scripts/utils.sh` – utility scripts
- `Caddyfile` – reverse proxy configuration
- `workspace/` & `vscode-config/` – persistent volumes

## 🔒 Security

- The `.env` file is generated from Doppler and should not be committed.
- SSH keys are stored in `.ssh/` with correct permissions.
- Keep your `DOPPLER_TOKEN` and other secrets safe.

## 🤝 Contributing

Contributions are welcome! Fork, create a branch (or work on `main`) and submit a Pull Request.

