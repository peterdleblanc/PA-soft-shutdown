# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains a single PowerShell script (`PA_soft_shutdown.ps1`) that performs a graceful (soft) shutdown of a Palo Alto Networks firewall over SSH.

## Usage

```powershell
# With confirmation prompt
.\PA_soft_shutdown.ps1 -FirewallIP "192.168.1.1" -Username "admin" -Password (ConvertTo-SecureString "password" -AsPlainText -Force)

# Skip confirmation prompt
.\PA_soft_shutdown.ps1 -FirewallIP "192.168.1.1" -Username "admin" -Password (ConvertTo-SecureString "password" -AsPlainText -Force) -Force
```

## Dependencies

- **Posh-SSH** PowerShell module (auto-installed if missing via `Install-Module`)
- PowerShell 5.1+ or PowerShell Core

## How It Works

1. Ensures `Posh-SSH` module is available, installing it if needed
2. Prompts for confirmation unless `-Force` is passed
3. Opens an SSH shell stream (not a direct command — uses interactive shell to handle the Junos/PAN-OS `request shutdown system` prompt)
4. Waits 20 seconds after login for the system to be ready
5. Sends `request shutdown system`, then confirms with `y` when the device prompts `Do you want to continue?`
6. Expects `system is going down` or `system halt` in the response to verify success

## Key Design Notes

- Uses `New-SSHShellStream` instead of `Invoke-SSHCommand` because the PAN-OS shutdown command requires interactive confirmation
- `SecureString` is used for the password parameter; it is briefly converted to plaintext in-memory via `Marshal::SecureStringToBSTR` for SSH credential construction, and the BSTR is zeroed in the `finally` block
- The 20-second sleep after login is intentional — the comment in the code references an original 45-second value that was reduced; adjust if the device needs more time before accepting commands
