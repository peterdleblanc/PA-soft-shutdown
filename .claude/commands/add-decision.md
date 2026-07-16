# Add Decision

Record an architectural or technical decision in DECISIONS.md while the context is fresh.

Usage: `/add-decision <short title>`

---

## Instructions

The decision title is: **$ARGUMENTS**

Decisions that aren't recorded get re-made. This command captures the full context now, before the reasoning fades.

---

### Step 1 — Read DECISIONS.md

Read `DECISIONS.md`. Note:
- The format of existing entries
- The highest decision number (DEC-NNN)
- The next available number

If `DECISIONS.md` does not exist, create it with a minimal header and proceed.

---

### Step 2 — Gather decision details

Ask the user these questions in a single message — do not ask one at a time:

```
To record this decision, I need a few details:

1. What was decided? — State it clearly in one or two sentences.
2. Why was this approach chosen? — The core reasoning.
3. What alternatives were considered? — List them, even briefly.
4. What tradeoffs were accepted? — What does this choice cost us?
5. Who approved it? (optional) — Name, role, or "team consensus"
```

Wait for the user's response before proceeding.

---

### Step 3 — Draft the entry

Format the entry following the existing DECISIONS.md pattern:

```
## DEC-NNN — [title]

**Date:** YYYY-MM-DD
**Status:** Accepted
**Decided by:** [approver or "Team consensus"]

### Decision
[Clear one-to-two sentence statement of what was decided]

### Context
[Why this decision was needed — what problem it solves or constraint it addresses]

### Alternatives Considered
- **[Alternative 1]** — [why it was rejected]
- **[Alternative 2]** — [why it was rejected]

### Rationale
[Core reasoning for the chosen approach]

### Tradeoffs Accepted
[What this choice costs — technical debt, limitations, or constraints we're living with]

---
```

---

### Step 4 — Show for confirmation

Display the full draft entry and ask: "Does this look correct? Confirm to add it to DECISIONS.md, or tell me what to change."

Wait for confirmation.

---

### Step 5 — Insert into DECISIONS.md

Add the confirmed entry after the last existing decision entry.

---

### Step 6 — Confirm

Print:

```
Decision recorded: DEC-NNN — [title]
Date: [today]
Status: Accepted
```
