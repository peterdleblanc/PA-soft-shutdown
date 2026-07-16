# Docker Logs

Stream logs from one service or all services.

Usage: `/docker-logs` (all) or `/docker-logs [service-name]` or `/docker-logs [service-name] --lines 100`

---

## Instructions

### Step 1 — Parse arguments

Check `$ARGUMENTS`:
- Empty → show logs for all services
- A service name → show logs for that service only
- `--lines N` anywhere in the arguments → use that as the tail count (default: 50)
- `--follow` or `-f` anywhere → add the `-f` flag to stream live (note: this runs indefinitely — warn the user they can stop it with Ctrl+C)

If a service name was provided, verify it exists:
```
docker compose config --services
```

If not found, list available services and stop.

### Step 2 — Fetch logs

For all services:
```
docker compose logs --tail=[N] --timestamps
```

For one service:
```
docker compose logs --tail=[N] --timestamps [service-name]
```

For follow mode (live stream):
```
docker compose logs --follow --tail=[N] [service-name or empty]
```

Before starting follow mode, tell the user: "Streaming live logs — press Ctrl+C to stop."

### Step 3 — Highlight important patterns

After displaying logs, scan the output and call out any lines matching:
- `ERROR`, `FATAL`, `CRITICAL`, `Exception`, `Traceback` → flag as errors
- `WARN`, `WARNING` → flag as warnings
- `started`, `listening on`, `ready`, `connected` → flag as healthy signals

Print a brief summary at the end (unless in follow mode):

```
═══════════════════════════════════════════════════════
LOG SUMMARY
═══════════════════════════════════════════════════════

Service(s): [name(s)]
Lines shown: [N]

Errors:   [count or "none"]
Warnings: [count or "none"]
Signals:  [healthy signals found, or "none"]
═══════════════════════════════════════════════════════
```
