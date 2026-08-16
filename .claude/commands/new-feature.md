# New Feature

Create a complete feature specification in FEATURES.md before any code is written.

Usage: `/new-feature <feature name>`

---

## Instructions

The feature name is: **$ARGUMENTS**

Do not write any code until this command completes. The spec must exist before implementation begins.

---

### Step 1 — Read FEATURES.md

Read `FEATURES.md`. Note:
- The format used for existing feature entries
- The highest feature number (FEA-NNN)
- The next available number

If `FEATURES.md` does not exist, create it with a minimal header and proceed.

---

### Step 2 — Gather spec details

Ask the user these questions in a single message — do not ask one at a time:

```
To create the feature spec for "$ARGUMENTS", I need a few details:

1. One-sentence description — What does this feature do for the user?
2. User-facing fields/inputs — What data does the user provide? (or "None")
3. API endpoints — What routes does this add or change? (or "None")
4. Business rules — What constraints, validations, or logic must be enforced?
5. Acceptance criteria — How do we know it's done? List 2–4 specific, testable conditions.
6. Out of scope — What are you explicitly NOT building in this feature?
```

Wait for the user's response before proceeding.

---

### Step 3 — Write the spec entry

Using the user's answers, draft a new entry following the existing FEATURES.md format. The entry must include:

- Feature number: FEA-NNN (next in sequence)
- Status: `Draft`
- Last Updated: today's date
- Description (one paragraph)
- Fields/Inputs section
- API Endpoints section
- Business Rules (numbered list)
- Acceptance Criteria (checkboxes)
- Out of Scope section

---

### Step 4 — Show for confirmation

Display the full draft entry and ask: "Does this spec look correct? Confirm to add it to FEATURES.md, or tell me what to change."

Wait for confirmation.

---

### Step 5 — Insert into FEATURES.md

Add the confirmed entry after the last existing feature, before any footer or notes.

---

### Step 5B — Put it on the board

A spec in FEATURES.md is a description; a ticket is work someone can see is
outstanding. Create the ticket so the feature does not exist only in a file
nobody opens.

**Prefer a ROADMAP.md checkbox** if this feature belongs to a phase — PCC scans
those into tickets automatically, which keeps the roadmap and the board in step
without a second source of truth.

Otherwise, `resolve_project` on this repo's absolute path (`pwd`), then
`create_task` with the feature name, a one-line description, and a priority you
have asked the user for rather than assumed. This is a write and really mutates
PCC.

If toolset-mcp is unavailable, say so in one line — the spec is written either
way.

---

### Step 6 — Confirm

Print:

```
Feature spec created: FEA-NNN — [feature name]
Status: Draft

Implementation may now begin. Stay within what's defined in the spec.
Reference it explicitly: "Implement FEA-NNN from FEATURES.md — nothing beyond what's defined there."
```
