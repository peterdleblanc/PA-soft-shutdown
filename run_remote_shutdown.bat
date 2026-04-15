@echo off
setlocal

:: ============================================================
:: Remotely executes PA_soft_shutdown.ps1 on another Windows
:: machine via PowerShell Remoting (WinRM).
::
:: Prerequisites on the REMOTE machine (run once as admin):
::   winrm quickconfig
:: ============================================================

echo.
echo === Palo Alto Soft Shutdown - Remote Launcher ===
echo.

set /p REMOTE_HOST=Remote Windows machine (hostname or IP):
set /p REMOTE_USER=Remote machine username (e.g. .\admin or DOMAIN\user):
set /p FIREWALL_IP=Firewall IP:
set /p FIREWALL_USER=Firewall username:

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
:: complex quoting/escaping inside -Command
set "PS_TEMP=%TEMP%\pa_shutdown_%RANDOM%.ps1"

> "%PS_TEMP%" (
    echo $ErrorActionPreference = 'Stop'
    echo.
    echo # Collect passwords securely
    echo $fwPass     = Read-Host 'Firewall password'      -AsSecureString
    echo $remotePass = Read-Host 'Remote machine password' -AsSecureString
    echo.
    echo # Build credential for the remote Windows machine
    echo $remoteCred = New-Object System.Management.Automation.PSCredential^('%REMOTE_USER%', $remotePass^)
    echo.
    echo # Open PS remoting session
    echo Write-Host 'Connecting to %REMOTE_HOST%...'
    echo $session = New-PSSession -ComputerName '%REMOTE_HOST%' -Credential $remoteCred -ErrorAction Stop
    echo.
    echo # Copy the shutdown script to the remote machine
    echo Write-Host 'Copying script to remote machine...'
    echo Copy-Item -Path '%SCRIPT_SRC%' -Destination 'C:\Windows\Temp\PA_soft_shutdown.ps1' -ToSession $session -Force
    echo.
    echo # Extract firewall password to pass over the (encrypted) WinRM channel,
    echo # then re-wrap as SecureString on the remote side.
    echo $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR^($fwPass^)
    echo $p = [Runtime.InteropServices.Marshal]::PtrToStringAuto^($b^)
    echo [Runtime.InteropServices.Marshal]::ZeroFreeBSTR^($b^)
    echo.
    echo # Run the script on the remote machine
    echo Write-Host 'Executing shutdown script on %REMOTE_HOST%...'
    echo Invoke-Command -Session $session -ArgumentList '%FIREWALL_IP%', '%FIREWALL_USER%', $p -ScriptBlock {
    echo     param^($fwIP, $fwUser, $pw^)
    echo     $sec = ConvertTo-SecureString $pw -AsPlainText -Force
    echo     ^& 'C:\Windows\Temp\PA_soft_shutdown.ps1' -FirewallIP $fwIP -Username $fwUser -Password $sec -Force
    echo }
    echo.
    echo Remove-PSSession $session -ErrorAction SilentlyContinue
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
    echo   1. Ensure WinRM is enabled on %REMOTE_HOST%:
    echo      Run as admin on that machine: winrm quickconfig
    echo   2. If connecting across domains/workgroups you may need:
    echo      winrm set winrm/config/client @{TrustedHosts="%REMOTE_HOST%"}
    echo   3. Verify the remote account has admin rights on %REMOTE_HOST%.
    pause
    exit /b %RC%
)

pause
