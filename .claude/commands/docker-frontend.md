# Docker Frontend

Rebuild and restart the frontend service. Auto-detects the service from docker-compose.yml.

Usage: `/docker-frontend`

---

## Instructions

### Step 1 — Find the frontend service

Run:
```
docker compose config --services
```

Look for a service whose name contains any of these patterns (case-insensitive):
`frontend`, `front`, `web`, `ui`, `client`, `app`, `react`, `next`, `vue`, `svelte`, `nginx`

If exactly one match → use it, no need to ask.

If multiple matches → list them and ask: "Which service is the frontend? [list options]"

If no match → list all services and ask: "Which of these is the frontend service? [list options]"

Wait for the user to confirm or choose before proceeding.

### Step 2 — Show current state

Run:
```
docker compose ps [service-name] --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

### Step 3 — Rebuild and restart

Run:
```
docker compose up -d --build [service-name]
```

Stream the build output as it runs.

If the build fails:
- Show the full error
- Check for: missing node_modules (try `npm install` step in Dockerfile), syntax errors, missing env vars
- Show the last 30 lines of logs: `docker compose logs --tail=30 [service-name]`

### Step 4 — Confirm it's up

Run:
```
docker compose ps [service-name] --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

Print:

```
═══════════════════════════════════════════════════════
FRONTEND REBUILT
═══════════════════════════════════════════════════════

Service: [service-name]
Status:  [running | error]
URL:     http://localhost:[port]  (if port is mapped)

[If error: last 20 log lines shown below]
═══════════════════════════════════════════════════════
```
