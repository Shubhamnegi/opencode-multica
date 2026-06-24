# Multica Docker Image with OpenCode, Claude Code, and Hermes Agent

A Docker image with [OpenCode](https://opencode.ai), [Claude Code](https://code.claude.com), and [Hermes Agent](https://hermes-agent.nousresearch.com) pre-installed alongside the [Multica](https://multica.ai) daemon. Run any of these coding agents as a managed Multica runtime without installing anything on your host machine.

---

## Prerequisites

- Docker installed on your machine
- A [Multica account](https://multica.ai) (cloud or self-hosted)
- An [OpenRouter API key](https://openrouter.ai/keys) (for Claude Code and Hermes Agent via OpenRouter)
- Alternatively, individual provider keys (Anthropic, OpenAI, etc.) for direct provider access

---

## Build the Image

```bash
git clone https://github.com/Shubhamnegi/opencode-multica.git
cd opencode-multica
docker build -t multica-agents .
```

---

## First-Time Setup

Before the daemon can run, you need to authenticate Multica and configure your preferred agent(s). Do this once — credentials are saved to volumes and reused on subsequent runs.

**Step 1: Log in to Multica**

```bash
docker run -it \
  -v multica-config:/root/.multica \
  multica-agents \
  multica login
```

This opens a browser for OAuth. Complete the login, then the token is saved to the `multica-config` volume.

**Step 2: Configure OpenRouter (for Claude Code and Hermes)**

If you want to use Claude Code or Hermes Agent through OpenRouter, set your API key via environment variable:

```bash
docker run -it \
  -v hermes-config:/root/.hermes \
  -e OPENROUTER_API_KEY=your_openrouter_key_here \
  multica-agents \
  hermes config set OPENROUTER_API_KEY $OPENROUTER_API_KEY
```

**Step 3: Configure Claude Code with OpenRouter**

Claude Code requires specific environment variables to route through OpenRouter. Run the container with the correct env vars and launch Claude to authenticate:

```bash
docker run -it \
  -v claude-config:/root/.claude \
  -e OPENROUTER_API_KEY=your_openrouter_key_here \
  -e ANTHROPIC_BASE_URL="https://openrouter.ai/api" \
  -e ANTHROPIC_AUTH_TOKEN="your_openrouter_key_here" \
  -e ANTHROPIC_API_KEY="" \
  multica-agents \
  claude
```

**Step 4: Configure Hermes Agent with OpenRouter**

```bash
docker run -it \
  -v hermes-config:/root/.hermes \
  -e OPENROUTER_API_KEY=your_openrouter_key_here \
  multica-agents \
  hermes model
```

Select **OpenRouter** as the provider and choose your preferred model.

**Step 5: Configure OpenCode with your LLM provider**

```bash
docker run -it \
  -v opencode-config:/root/.config/opencode \
  -v opencode-data:/root/.local/share/opencode \
  -e ANTHROPIC_API_KEY=your_key_here \
  multica-agents \
  opencode
```

Follow the in-TUI prompts to select your provider. Exit once configured — credentials are saved to the `opencode-data` volume.

---

## Running the Daemon

Once Multica is authenticated and at least one agent is configured, start the daemon:

```bash
docker run -d \
  --name multica-agent \
  -v multica-config:/root/.multica \
  -v opencode-config:/root/.config/opencode \
  -v opencode-data:/root/.local/share/opencode \
  -v claude-config:/root/.claude \
  -v hermes-config:/root/.hermes \
  -v $(pwd):/workspace \
  multica-agents
```

To pass OpenRouter keys at runtime (for Claude Code and Hermes):

```bash
docker run -d \
  --name multica-agent \
  -v multica-config:/root/.multica \
  -v opencode-config:/root/.config/opencode \
  -v opencode-data:/root/.local/share/opencode \
  -v claude-config:/root/.claude \
  -v hermes-config:/root/.hermes \
  -v $(pwd):/workspace \
  -e OPENROUTER_API_KEY=your_openrouter_key_here \
  -e ANTHROPIC_BASE_URL="https://openrouter.ai/api" \
  -e ANTHROPIC_AUTH_TOKEN="your_openrouter_key_here" \
  -e ANTHROPIC_API_KEY="" \
  multica-agents
```

The daemon starts in the foreground inside the container (Docker keeps it alive). Within a few seconds, your runtime should appear in **Settings → Runtimes** in the Multica web app.

---

## Connecting to a Self-Hosted Multica Server

If you're running Multica on your own infrastructure, set the server URLs before logging in:

```bash
docker run -it \
  -v multica-config:/root/.multica \
  -e MULTICA_SERVER_URL=wss://api.your-server.com/ws \
  -e MULTICA_APP_URL=https://app.your-server.com \
  multica-agents \
  multica login
```

Then start the daemon with the same env vars:

```bash
docker run -d \
  --name multica-agent \
  -v multica-config:/root/.multica \
  -v opencode-config:/root/.config/opencode \
  -v opencode-data:/root/.local/share/opencode \
  -v claude-config:/root/.claude \
  -v hermes-config:/root/.hermes \
  -v $(pwd):/workspace \
  -e MULTICA_SERVER_URL=wss://api.your-server.com/ws \
  -e MULTICA_APP_URL=https://app.your-server.com \
  multica-agents
```

---

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `MULTICA_SERVER_URL` | WebSocket URL of the Multica backend | `wss://api.multica.ai/ws` |
| `MULTICA_APP_URL` | HTTP URL of the Multica frontend | `https://app.multica.ai` |
| `MULTICA_OPENCODE_PATH` | Custom path to the `opencode` binary | auto-detected |
| `MULTICA_OPENCODE_MODEL` | Override the model OpenCode uses | provider default |
| `MULTICA_DAEMON_POLL_INTERVAL` | How often to poll for new tasks | `3s` |
| `MULTICA_DAEMON_HEARTBEAT_INTERVAL` | How often to send a heartbeat to the server | `15s` |
| `MULTICA_DAEMON_MAX_CONCURRENT_TASKS` | Max tasks running in parallel | `20` |
| `OPENROUTER_API_KEY` | OpenRouter API key (for Claude Code and Hermes) | — |
| `ANTHROPIC_BASE_URL` | Anthropic API base URL (set to `https://openrouter.ai/api` for OpenRouter) | — |
| `ANTHROPIC_AUTH_TOKEN` | Auth token for Claude Code (set to your OpenRouter API key) | — |
| `ANTHROPIC_API_KEY` | Anthropic API key — must be set to `""` when using OpenRouter | — |
| `OPENAI_API_KEY` | OpenAI API key (if using OpenAI models) | — |

---

## Viewing Daemon Logs

```bash
docker logs -f multica-agent
```

Or exec into the container and use the Multica CLI directly:

```bash
docker exec -it multica-agent multica daemon status
docker exec -it multica-agent multica daemon logs -f
```

---

## Stopping and Restarting

```bash
# Stop
docker stop multica-agent

# Start again (credentials are preserved in volumes)
docker start multica-agent

# Remove the container entirely (volumes are kept)
docker rm multica-agent
```

---

## Volumes

| Volume | Purpose |
|---|---|
| `multica-config` | Multica auth token and daemon config (`~/.multica`) |
| `opencode-config` | OpenCode config file (`~/.config/opencode`) |
| `opencode-data` | OpenCode auth and session data (`~/.local/share/opencode`) |
| `claude-config` | Claude Code config and auth (`~/.claude`) |
| `hermes-config` | Hermes Agent config and auth (`~/.hermes`) |

These volumes persist your credentials across container restarts. To fully reset and re-authenticate, remove them:

```bash
docker volume rm multica-config opencode-config opencode-data claude-config hermes-config
```

---

## Troubleshooting

**Runtime not showing up in Multica UI**

Check that the daemon started cleanly:
```bash
docker logs multica-agent
```
Look for lines like `INF registered runtime provider=opencode` — if missing, the agent wasn't detected. Confirm the agent binary is on `PATH` inside the container.

**Heartbeat failures**

If you see `WRN heartbeat failed` in the logs, the container can't reach the Multica server. Check your `MULTICA_SERVER_URL` and that the container has outbound internet access.

**OpenCode auth errors**

Re-run the Step 5 setup command to re-authenticate your LLM provider. The `opencode-data` volume holds the credentials.

**Claude Code auth errors**

Ensure `ANTHROPIC_API_KEY` is set to `""` (empty string), not unset. If you previously logged in with Anthropic directly, run `/logout` inside Claude Code and restart. Verify with `/status` that the auth token shows `ANTHROPIC_AUTH_TOKEN` and base URL is `https://openrouter.ai/api`.

**Hermes Agent errors**

Run `hermes doctor` for diagnostics. If you see "No API key", verify your `OPENROUTER_API_KEY` is set correctly. Hermes requires a model with at least 64K context tokens.
