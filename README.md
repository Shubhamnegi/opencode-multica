# multica-opencode Docker Image

A Docker image with both [OpenCode](https://opencode.ai) and the [Multica](https://multica.ai) daemon pre-installed, so you can run OpenCode as a managed Multica runtime without installing anything on your host machine.

---

## Prerequisites

- Docker installed on your machine
- A [Multica account](https://multica.ai) (cloud or self-hosted)
- An API key for your LLM provider (Anthropic, OpenAI, etc.)

---

## Build the Image

```bash
git clone https://github.com/your-org/multica-opencode-docker.git
cd multica-opencode-docker
docker build -t multica-opencode .
```

---

## First-Time Setup

Before the daemon can run, you need to authenticate both Multica and OpenCode. Do this once — credentials are saved to volumes and reused on subsequent runs.

**Step 1: Log in to Multica**

```bash
docker run -it \
  -v multica-config:/root/.multica \
  multica-opencode \
  multica login
```

This opens a browser for OAuth. Complete the login, then the token is saved to the `multica-config` volume.

**Step 2: Configure your LLM provider for OpenCode**

```bash
docker run -it \
  -v opencode-config:/root/.config/opencode \
  -v opencode-data:/root/.local/share/opencode \
  -e ANTHROPIC_API_KEY=your_key_here \
  multica-opencode \
  opencode
```

Follow the in-TUI prompts to select your provider. Exit once configured — credentials are saved to the `opencode-data` volume.

---

## Running the Daemon

Once both tools are authenticated, start the daemon:

```bash
docker run -d \
  --name multica-agent \
  -v multica-config:/root/.multica \
  -v opencode-config:/root/.config/opencode \
  -v opencode-data:/root/.local/share/opencode \
  -v $(pwd):/workspace \
  multica-opencode
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
  multica-opencode \
  multica login
```

Then start the daemon with the same env vars:

```bash
docker run -d \
  --name multica-agent \
  -v multica-config:/root/.multica \
  -v opencode-config:/root/.config/opencode \
  -v opencode-data:/root/.local/share/opencode \
  -v $(pwd):/workspace \
  -e MULTICA_SERVER_URL=wss://api.your-server.com/ws \
  -e MULTICA_APP_URL=https://app.your-server.com \
  multica-opencode
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
| `ANTHROPIC_API_KEY` | Anthropic API key (if using Claude models) | — |
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

These volumes persist your credentials across container restarts. To fully reset and re-authenticate, remove them:

```bash
docker volume rm multica-config opencode-config opencode-data
```

---

## Troubleshooting

**Runtime not showing up in Multica UI**

Check that the daemon started cleanly:
```bash
docker logs multica-agent
```
Look for lines like `INF registered runtime provider=opencode` — if missing, OpenCode wasn't detected. Confirm `MULTICA_OPENCODE_PATH` is set correctly or that `opencode` is on `PATH` inside the container.

**Heartbeat failures**

If you see `WRN heartbeat failed` in the logs, the container can't reach the Multica server. Check your `MULTICA_SERVER_URL` and that the container has outbound internet access.

**OpenCode auth errors**

Re-run the Step 2 setup command to re-authenticate your LLM provider. The `opencode-data` volume holds the credentials.
