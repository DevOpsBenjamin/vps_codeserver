FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    ca-certificates \
    sudo \
    openssh-client \
    netcat-openbsd \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Install uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install Claude Code (when available)
RUN npm install -g @anthropic-ai/claude-code || echo "Claude Code not available yet"

# Install Gemini CLI
RUN npm install -g @google/gemini-cli

# Create vscode user
RUN useradd -m -s /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Python tools for vscode user
USER vscode
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/vscode/.local/bin:$PATH"
RUN uv tool install crewai

# Setup workspace
WORKDIR /workspace
ENV HOME=/home/vscode

# Expose code-server port
EXPOSE 8080

# Simple startup: just run code-server
CMD ["code-server", "/workspace", "--bind-addr", "0.0.0.0:8080", "--auth", "password", "--disable-telemetry"]
