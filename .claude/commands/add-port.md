# Add Port

Claim a port in the fleet-wide registry (PCC) and mirror it into PORT_REGISTRY.md.

Usage: `/add-port <service-name> [port-number]`

---

## Instructions

The service and port are: **$ARGUMENTS**

Parse the arguments: the first token is the service name, the second — **optional** —
is a requested port number.

**If no port was given, do not pick one yourself.** Ask PCC for a free one. Hand-picked
ports are how two projects end up silently bound to the same number; the shared
registry exists to prevent exactly that.

If the service name is missing, ask for it before proceeding.

---

### Step 1 — Resolve the project and check the live registry

Call `resolve_project` with this repo's absolute path (`pwd`), and keep the id it
returns. Identity is keyed on the path, not the name — names collide across the fleet.

Then call `list_ports` for what is already claimed.

**If toolset-mcp is unavailable** (no MCP tools registered, or the call errors), say so
in one line — `PCC unreachable, falling back to PORT_REGISTRY.md only` — and skip to the
fallback path in Step 2b. Do not silently degrade: a port claimed only in markdown is
invisible to every other project.

---

### Step 2a — Claim the port (PCC path)

- **No port requested:** call `find_free_port`, then `allocate_port` to claim what it
  returned. Report both the search and the claim.
- **A specific port requested:** check it against `list_ports` first. If it is taken,
  stop and report the conflict:

  ```
  ⚠ Port conflict: [port] is already claimed by [existing project/service].

  Free alternative: [what find_free_port returns]
  ```

  Do not claim a conflicting port. Ask the user whether to take the alternative.

  If it is free, call `allocate_port`.

**`allocate_port` is a write — it really mutates PCC.** Only call it once the details in
Step 3 are settled, so a half-answered command does not leave an orphan claim.

---

### Step 2b — Fallback (PCC unreachable)

Read `PORT_REGISTRY.md` and extract every registered port. If the file does not exist,
create it with a minimal header and an empty port table.

If the requested port is already listed, stop and report the conflict as above. If no
port was requested, ask the user to name one — this path cannot search the fleet, so
say plainly that the choice is unverified against other projects and should be
re-checked with `/add-port` once PCC is back.

---

### Step 3 — Gather service details

Ask the user in a single message:

```
Claiming port [port] for [service]. A few quick details:

1. Protocol — HTTP / HTTPS / TCP / UDP / WebSocket?
2. Description — One sentence: what does this service do?
3. Environment — Dev only / prod only / both?
```

Wait for the user's response, then perform the `allocate_port` write from Step 2a.

---

### Step 4 — Mirror into PORT_REGISTRY.md

Add a row to the port table following the existing format: port, service, protocol,
description, environment. Sort numerically if the table is ordered.

**PORT_REGISTRY.md is the human-readable mirror, not the authority.** PCC holds the
real claim. If the two disagree, PCC is usually right — but its data is a snapshot of
its last scan, so `rescan_ports` is the other explanation worth trying.

---

### Step 5 — Confirm

Print, naming which path was taken:

```
Port claimed:    [port] → [service]
Protocol:        [protocol]
Environment:     [environment]
Registry:        PCC (allocate_port) + PORT_REGISTRY.md
                 — or — PORT_REGISTRY.md only (PCC unreachable)
```
