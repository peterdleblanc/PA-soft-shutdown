# Add Port

Register a new service port in PORT_REGISTRY.md after checking for conflicts.

Usage: `/add-port <service-name> <port-number>`

---

## Instructions

The service and port are: **$ARGUMENTS**

Parse the arguments: the first token is the service name, the second is the port number.
If either is missing, ask the user for the missing value before proceeding.

---

### Step 1 — Read PORT_REGISTRY.md

Read `PORT_REGISTRY.md`. Extract every port number currently registered.

If `PORT_REGISTRY.md` does not exist, create it with a minimal header and an empty port table, then proceed.

---

### Step 2 — Check for conflict

If the requested port is already registered, stop immediately:

```
⚠ Port conflict: [port] is already assigned to [existing service].

Choose a different port. All current assignments are in PORT_REGISTRY.md.
```

Do not proceed if there is a conflict.

---

### Step 3 — Gather service details

Ask the user in a single message:

```
Adding port [port] for [service]. A few quick details:

1. Protocol — HTTP / HTTPS / TCP / UDP / WebSocket?
2. Description — One sentence: what does this service do?
3. Environment — Dev only / prod only / both?
```

Wait for the user's response.

---

### Step 4 — Add the entry

Add a new row to the port table in `PORT_REGISTRY.md` following the existing format. Include:
- Port number (sorted numerically if the table is ordered)
- Service name
- Protocol
- Description
- Environment

---

### Step 5 — Confirm

Print:

```
Port registered: [port] → [service]
Protocol:        [protocol]
Environment:     [environment]

PORT_REGISTRY.md updated. No further action needed.
```
