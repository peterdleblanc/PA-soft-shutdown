# Review TODO — PA-soft-shutdown

Generated 2026-05-20. Doc Health 5.9 (failed — caveat) · Code Review 51.6 (partial).

Published to the ProjectAssessment dashboard: reports #77 (doc) / #78 (code).

> **Note:** This is a **2-file utility script** — one PowerShell soft-shutdown for a Palo Alto firewall (`PA_soft_shutdown.ps1`) plus a `.bat` launcher. The 5.9 doc score is a framework mismatch, not neglect: CLAUDE.md documents invocation, the Posh-SSH dependency, and the exact SSH-prompt handshake — for the scope, that's adequate. The real findings are credential-handling hygiene and the absence of any safety affordance on a script whose entire job is to power off network infrastructure.

## P1 — Credential-handling pattern
- [ ] **Stop demonstrating `ConvertTo-SecureString "password" -AsPlainText`** in CLAUDE.md / usage — these are *firewall admin* creds. Switch the documented example to `Get-Credential` (or PowerShell SecretManagement).
- [ ] **Add a `-WhatIf` / dry-run path** — print the planned commands and exit without sending `request shutdown system`. This is the cheapest safety affordance for a destructive script.

## P1 — Human entry point
- [ ] **Add a short `README.md`** (can be a near-copy of CLAUDE.md). The repo currently has no human-facing landing file — a host viewer browsing on GitHub sees only the AI-facing CLAUDE.md by convention.

## P2 — Tooling + tests
- [ ] **Pin `Posh-SSH`** — `Install-Module -RequiredVersion <x>` instead of unpinned auto-install.
- [ ] **Add a Pester test** for the SSH-prompt-handshake parsing (the `request shutdown system` → `Do you want to continue? y` flow). Doesn't require a real device — mock the stream.
- [ ] **Add PSScriptAnalyzer** with the default rule set; it's a single CI step and would catch the credential-handling smell automatically.

## Do NOT
- [ ] **Do not add the rest of the 18-file framework** (ROADMAP / CI_CD / DATABASE / DEPLOYMENT / etc.) — it's a 2-file script, those files would be noise.

## Strengths
- CLAUDE.md is genuinely accurate for the scope — usage, Posh-SSH dependency, the 20-second post-login wait, and the exact handshake (`request shutdown system` → `y` → expect `system is going down`).
- Uses `New-SSHShellStream` (the safe interactive form) instead of `Invoke-SSHCommand` — required because PAN-OS prompts mid-command.
- `SecureString` for the password parameter; BSTR zeroed in the `finally` block.
- Nothing sensitive tracked; 0 TODO; 2 small focused files.
