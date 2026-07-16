# Docker Shell

Open an interactive shell inside a running container for debugging and testing.

Usage: `/docker-shell` or `/docker-shell [service-name]`

---

## Instructions

### Step 1 — Identify target container

Check `$ARGUMENTS`:
- If a service name was given → use it
- If empty → list running services and ask which one

Run:
```
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Service}}"
```

Show only containers with status `running`. If nothing is running, tell the user to run `/docker-start` first.

If a service was specified but isn't running, say so and stop.

### Step 2 — Detect available shell

Try to find the best shell available in the container, in this order:
1. `bash`
2. `sh`

Run a quick check:
```
docker compose exec [service-name] which bash 2>/dev/null || docker compose exec [service-name] which sh
```

Use whichever is found.

### Step 3 — Print context before opening shell

Tell the user what they're entering and useful commands for that container type:

Detect container type from the service name or image (from `docker compose config`):

- Python/Django/Flask → suggest: `python manage.py shell`, `pip list`, `python -c "..."`, check `/app` for source
- Node/Express → suggest: `node`, `npm test`, check `/app` for source
- PostgreSQL/MySQL → suggest: `psql -U $POSTGRES_USER $POSTGRES_DB` or `mysql -u root -p`
- Redis → suggest: `redis-cli`
- Generic → suggest: `ls /app`, `env | grep -v SECRET`

Print:
```
Opening shell in: [service-name]
Shell: [bash | sh]
Working dir: /app (or detected from Dockerfile WORKDIR)

Useful commands in this container:
  [2-3 relevant suggestions based on container type]

Type 'exit' to return.
```

### Step 4 — Open the shell

Run:
```
docker compose exec -it [service-name] [bash or sh]
```

This is an interactive command — the user takes over from here.

After the shell exits, print:
```
Shell closed. Back in Claude Code.
```
