# Schema Change

Update DATABASE.md when a migration is applied or a schema change is made.

Usage: `/schema-change <description>`

---

## Instructions

The change description is: **$ARGUMENTS**

DATABASE.md is the human-readable schema. It must stay in sync with the actual database.
This command updates it immediately after a migration runs — don't let the two drift.

---

### Step 1 — Read DATABASE.md

Read `DATABASE.md`. Note:
- The migration log section and its format
- Which tables are documented and how they're structured
- The current schema state

If `DATABASE.md` does not exist, tell the user: "DATABASE.md does not exist. Run bootstrap.sh first or create it manually before using /schema-change."

---

### Step 2 — Gather change details

Ask the user these questions in a single message:

```
To update DATABASE.md for this schema change, I need a few details:

1. Migration filename — What is the migration file called? (e.g., 003_add_user_roles.sql)
2. Tables affected — Which tables were added, modified, or dropped?
3. For each affected table:
   - What columns were added, changed, or removed? (name, type, constraints)
   - Were any indexes added or dropped?
   - Were any constraints or defaults added or changed?
4. Relationships — Did any foreign key relationships change?
```

Wait for the user's response before proceeding.

---

### Step 3 — Update the migration log

Find the migration log section in DATABASE.md. Prepend a new entry using the existing format:

```
| YYYY-MM-DD | [migration filename] | [brief description of change] |
```

---

### Step 4 — Update table documentation

For each affected table:

- **Table added:** Create a new table section with columns, types, nullability, constraints, and indexes documented.
- **Table modified:** Update the existing section — add new columns, remove dropped ones, update changed types or constraints. Do not leave stale column entries.
- **Table dropped:** Remove the section entirely. Note it in the migration log entry.

---

### Step 5 — Show for confirmation

Display a summary of the changes made to DATABASE.md and ask:
"Does this accurately reflect the schema change? Confirm to save, or tell me what to correct."

Wait for confirmation before writing.

---

### Step 6 — Confirm

Print:

```
DATABASE.md updated for: [description]
Migration:       [filename]
Tables affected: [list]

Schema documentation is now in sync with the database.
```
