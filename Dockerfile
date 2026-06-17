FROM node:20-slim

RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install opencode (requires Node 18+)
RUN npm install -g opencode-ai

# Install multica CLI
RUN curl -fsSL https://raw.githubusercontent.com/multica-ai/multica/main/scripts/install.sh | bash

ENV PATH="/root/.local/bin:$PATH"

WORKDIR /workspace

CMD ["multica", "daemon", "start", "--foreground"]
