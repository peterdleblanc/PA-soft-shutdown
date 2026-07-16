# Docker Backend

Rebuild and restart the backend service. Auto-detects the service from docker-compose.yml.

Usage: `/docker-backend`

---

## Instructions

### Step 1 — Find the backend service

Run:
```
docker compose config --services
```

Look for a service whose name contains any of these patterns (case-insensitive):
`backend`, `back`, `api`, `server`, `app`, `django`, `flask`, `fastapi`, `express`, `rails`, `laravel`, `spring`, `worker`

If exactly one match → use it, no need to ask.

If multiple matches → list them and ask: "Which service is the backend? [list options]"

If no match → list all services and ask: "Which of these is the backend service? [list options]"

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
- Check for: missing requirements.txt packages, failed pip/npm install, missing env vars, migration errors
- Show the last 30 lines of logs: `docker compose logs --tail=30 [service-name]`

### Step 4 — Confirm it's up

Run:
```
docker compose ps [service-name] --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

Print:

```
═══════════════════════════════════════════════════════
BACKEND REBUILT
═══════════════════════════════════════════════════════

Service: [service-name]
Status:  [running | error]
Port:    [mapped port(s) if any]

[If error: last 20 log lines shown below]
═══════════════════════════════════════════════════════
```
