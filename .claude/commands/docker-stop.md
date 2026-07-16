# Docker Stop

Stop all running services.

Usage: `/docker-stop` or `/docker-stop --volumes` to also remove volumes

---

## Instructions

### Step 1 — Check what's running

Run:
```
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

If nothing is running, tell the user and stop.

### Step 2 — Confirm volume removal if requested

If the user passed `--volumes` in `$ARGUMENTS`:

Warn the user:
```
⚠ --volumes will delete all named volumes for this project.
  This means database data, uploaded files, and any other
  persisted state will be permanently removed.

  Proceed? (yes/no)
```

Wait for confirmation before continuing. If they say no, run a plain `docker compose down` instead.

### Step 3 — Stop services

If `--volumes` was confirmed:
```
docker compose down --volumes
```

Otherwise:
```
docker compose down
```

Show the full output as it runs.

### Step 4 — Verify and report

Run:
```
docker compose ps
```

Print this summary block:

```
═══════════════════════════════════════════════════════
DOCKER STOP
═══════════════════════════════════════════════════════

Stopped: [list of services that were running]
Volumes removed: [yes | no]

All services stopped.
═══════════════════════════════════════════════════════
```
