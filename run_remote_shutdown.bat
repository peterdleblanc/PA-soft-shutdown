@echo off
setlocal

:: ============================================================
:: Remotely executes PA_soft_shutdown.ps1 on another Windows
:: machine via SSH (OpenSSH).
::
:: Prerequisites on the REMOTE machine:
::   OpenSSH Server installed and running.
::   Install: Settings > Apps > Optional Features > OpenSSH Server
::   Start:   net start sshd
:: ============================================================

echo.
echo === Palo Alto Soft Shutdown - Remote Launcher (SSH) ===
echo.

set /p REMOTE_HOST=Remote machine (hostname or IP):
set /p REMOTE_USER=Remote machine SSH username:
set /p FIREWALL_IP=Firewall IP:
set /p FIREWALL_USER=Firewall username:
set /p SSH_KEY=SSH key file (leave blank for password auth):

:: Build path to the PS1 script (same folder as this .bat)
set "SCRIPT_SRC=%~dp0PA_soft_shutdown.ps1"

:: Verify the script exists before going further
if not exist "%SCRIPT_SRC%" (
    echo.
    echo ERROR: PA_soft_shutdown.ps1 not found at: %SCRIPT_SRC%
    pause
    exit /b 1
)

:: Write a temp PowerShell helper script so we avoid
:: complex quoting/escaping in the SSH command
set "PS_TEMP=%TEMP%\pa_shutdown_%RANDOM%.ps1"

> "%PS_TEMP%" (
    echo $ErrorActionPreference = 'Stop'
    echo.
    echo # Collect firewall password securely
    echo $fwPass = Read-Host 'Firewall password' -AsSecureString
    echo $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR^($fwPass^)
    echo $p = [Runtime.InteropServices.Marshal]::PtrToStringAuto^($b^)
    echo [Runtime.InteropServices.Marshal]::ZeroFreeBSTR^($b^)
    echo.
    echo # Build optional -i flag for key-based auth
    echo $keyArgs = if ('%SSH_KEY%' -ne '')^{ @^('-i', '%SSH_KEY%'^) ^} else ^{ @^(^) ^}
    echo.
    echo # Copy script to the remote machine via SCP
    echo # SSH will prompt for password here if not using a key
    echo Write-Host 'Copying script to %REMOTE_HOST%...'
    echo ^& scp @keyArgs '%SCRIPT_SRC%' '%REMOTE_USER%@%REMOTE_HOST%:C:/Windows/Temp/PA_soft_shutdown.ps1'
    echo if ($LASTEXITCODE -ne 0)^{ throw "SCP failed with exit code $LASTEXITCODE" ^}
    echo.
    echo # Build the remote PowerShell command, then base64-encode it so that
    echo # the firewall password and paths survive SSH quoting intact.
    echo $remoteCmd  = '$sec = ConvertTo-SecureString ''' + $p + ''' -AsPlainText -Force; '
    echo $remoteCmd += '^& ''C:\Windows\Temp\PA_soft_shutdown.ps1'' -FirewallIP ''%FIREWALL_IP%'' -Username ''%FIREWALL_USER%'' -Password $sec -Force'
    echo $encoded = [Convert]::ToBase64String^([Text.Encoding]::Unicode.GetBytes^($remoteCmd^)^)
    echo.
    echo # Execute on the remote machine via SSH
    echo Write-Host 'Executing shutdown script on %REMOTE_HOST%...'
    echo ^& ssh @keyArgs '%REMOTE_USER%@%REMOTE_HOST%' powershell -ExecutionPolicy Bypass -EncodedCommand $encoded
    echo if ($LASTEXITCODE -ne 0)^{ throw "SSH execution failed with exit code $LASTEXITCODE" ^}
    echo.
    echo Write-Host 'Done.'
)

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_TEMP%"
set "RC=%ERRORLEVEL%"

:: Always clean up the temp file
del "%PS_TEMP%" 2>nul

echo.
if %RC% NEQ 0 (
    echo Remote execution FAILED.
    echo.
    echo Troubleshooting:
    echo   1. Ensure OpenSSH Server is installed and running on %REMOTE_HOST%
    echo      Install: Settings ^> Apps ^> Optional Features ^> OpenSSH Server
    echo      Start:   net start sshd
    echo   2. Ensure OpenSSH Client is installed locally ^(built into Windows 10/11^)
    echo      Install: Settings ^> Apps ^> Optional Features ^> OpenSSH Client
    echo   3. For key auth, verify the public key is in the remote authorized_keys file
    pause
    exit /b %RC%
)

pause
