# Docker Rebuild

Rebuild one or all services after code changes, then restart them.

Usage: `/docker-rebuild` (all services) or `/docker-rebuild [service-name]`

---

## Instructions

### Step 1 — Identify target

Check `$ARGUMENTS`:
- If empty → rebuild all services
- If a service name was provided → rebuild only that service

Run to confirm the service exists (if one was specified):
```
docker compose config --services
```

If the named service isn't in the list, show the available services and stop.

### Step 2 — Rebuild

If rebuilding all:
```
docker compose up -d --build
```

If rebuilding one service:
```
docker compose up -d --build [service-name]
```

Stream the output as it runs — build output is useful to see in real time.

### Step 3 — Watch for errors

If the build fails:
- Show the full error
- Check for common causes:
  - Syntax error in Dockerfile → show the offending line
  - Missing dependency in package.json / requirements.txt → suggest running the install step
  - COPY file not found → the file may not exist or the path is wrong
  - Network error pulling base image → transient; suggest retry

If the build succeeds but the container exits immediately, show the logs:
```
docker compose logs --tail=50 [service-name]
```

### Step 4 — Report

Run:
```
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

Print:

```
═══════════════════════════════════════════════════════
DOCKER REBUILD
═══════════════════════════════════════════════════════

Rebuilt: [service name(s)]

Services:
  [one line per container: name | status | ports]

Health: [all running | X of Y running | errors detected]
═══════════════════════════════════════════════════════
```
