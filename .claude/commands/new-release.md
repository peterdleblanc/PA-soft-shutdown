# New Release

Walk through the full release checklist and ship a versioned release.

Usage: `/new-release <version>` (e.g., `/new-release 1.8.0`)

---

## Instructions

The target version is: **$ARGUMENTS**

Do not skip steps. Each one is a gate before tagging.

---

### Step 1 — Verify readiness

Run in parallel:
- `git status` — must be clean before releasing
- `git log --oneline -10` — review what's going into this release
- `git branch --show-current` — confirm you are on main (or the intended release branch)

If there are uncommitted changes, stop immediately:

```
⚠ Cannot release: there are uncommitted changes.
Commit or stash them before running /new-release.
```

---

### Step 2 — Read the changelog

Read `CHANGELOG.md`. Find the `## [Unreleased]` section.

If it is empty or missing, warn the user:

```
⚠ The [Unreleased] section is empty.
Add changelog entries before releasing, or confirm you want to ship with no documented changes.
```

Show the user the full content of `## [Unreleased]` and ask:
"This is what will be documented under v$ARGUMENTS. Does this look complete and accurate?"

Wait for confirmation before proceeding.

---

### Step 3 — Update CHANGELOG.md

In `CHANGELOG.md`:
1. Replace `## [Unreleased]` with `## [v$ARGUMENTS] — YYYY-MM-DD` (today's date)
2. Add a new `## [Unreleased]` section above the newly versioned block

---

### Step 4 — Bump version references

Check for these version references and update each one found:
- `VERSION` file in the project root — update to `$ARGUMENTS`
- `website/index.html` — update any version pill (e.g., `v1.5.0`) to `v$ARGUMENTS`
- `HANDOFF.md` — update any version reference in the current state section

List which files were updated.

---

### Step 5 — Confirm release scope

Show the user:

```
Files to be committed:
  CHANGELOG.md        — [Unreleased] → [v$ARGUMENTS] — YYYY-MM-DD
  [VERSION]           — bumped to $ARGUMENTS (if present)
  [other version-bumped files]

Tag to create: v$ARGUMENTS
Branch: [branch]

Confirm release commit and tag?
```

Wait for confirmation.

---

### Step 6 — Commit, tag, and push

Stage all modified files. Run:

```bash
git commit -m "chore(release): v$ARGUMENTS

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

git tag -a "v$ARGUMENTS" -m "Release v$ARGUMENTS"
git push
git push --tags
```

Show the commit SHA, tag, and push output.

---

### Step 7 — Display release summary

Print:

```
═══════════════════════════════════════════════════════
RELEASE SHIPPED: v$ARGUMENTS
═══════════════════════════════════════════════════════

Tag:     v$ARGUMENTS
Commit:  [SHA]
Branch:  [branch]

Changes in this release:
  [content from CHANGELOG for this version]

Next steps:
  - Create a GitHub release from the tag:
    gh release create v$ARGUMENTS --title "v$ARGUMENTS" --generate-notes
  - Update HANDOFF.md if it references the previous version
  - Announce to the team
═══════════════════════════════════════════════════════
```
