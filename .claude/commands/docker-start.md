# Docker Start

Start all services defined in docker-compose.yml.

Usage: `/docker-start`

---

## Instructions

### Step 1 — Find the compose file

Run:
```
ls docker-compose.yml docker-compose.yaml compose.yml compose.yaml 2>/dev/null | head -1
```

If no compose file is found, stop and tell the user: "No docker-compose file found in the current directory."

### Step 2 — Check current state

Run in parallel:
- `docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"` — what's already running
- `docker compose config --services` — all defined services

### Step 3 — Start services

Run:
```
docker compose up -d
```

If this fails, show the full error output and suggest common fixes:
- Port conflict → check PORT_REGISTRY.md and `docker ps` for what's using the port
- Image not found → run `/docker-rebuild` to build first
- Volume permission error → check that bind-mount paths exist

### Step 4 — Verify and report

Run:
```
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

Print this summary block:

```
═══════════════════════════════════════════════════════
DOCKER START
═══════════════════════════════════════════════════════

Services:
  [one line per container: name | status | ports]

Health: [all running | X of Y running | errors detected]
═══════════════════════════════════════════════════════
```

If any service failed to start, show its last 20 log lines:
```
docker compose logs --tail=20 [service-name]
```
