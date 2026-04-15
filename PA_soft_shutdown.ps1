[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FirewallIP,
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [Parameter(Mandatory=$true)]
    [SecureString]$Password,
    [Parameter(Mandatory=$false)]
    [switch]$Force
)
 
# First, ensure we have the required module
if (-not (Get-Module -ListAvailable -Name "Posh-SSH")) {
    Write-Host "Installing required Posh-SSH module..."
    Install-Module -Name Posh-SSH -Force -Scope CurrentUser
}
 
function Send-ShutdownCommand {
    param (
        [string]$IP,
        [string]$User,
        [SecureString]$Pass
    )
    try {
        Write-Host "Connecting to firewall..."
        # Convert SecureString to plain text for SSH
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Pass)
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        # Create SSH session with keyboard-interactive authentication
        $sessionParams = @{
            ComputerName = $IP
            Credential = New-Object System.Management.Automation.PSCredential($User, $Pass)
            AcceptKey = $true
            ConnectionTimeout = 60
            ErrorAction = 'Stop'
        }
        $SSHSession = New-SSHSession @sessionParams
        if ($SSHSession) {
            Write-Host "Successfully connected to $IP"
            try {
                # Create a shell stream
                $stream = New-SSHShellStream -SessionId $SSHSession.SessionId
                if ($stream) {
                    # Wait for initial prompt
                    Start-Sleep -Seconds 2
                    $initialOutput = $stream.Read()
                    Write-Host "Initial connection output: $initialOutput"
                    # Add 45 second pause after login
                    Write-Host "Waiting 20 seconds for system to be ready..."
                    Start-Sleep -Seconds 20 
                    # Send shutdown command
                    Write-Host "Sending shutdown command..."
                    $stream.WriteLine("request shutdown system")
                    Start-Sleep -Seconds 2
                    $shutdownOutput = $stream.Read()
                    Write-Host "Shutdown command output: $shutdownOutput"
                    # Check if we got the warning prompt
                    if ($shutdownOutput -match "Do you want to continue\?") {
                        # Send confirmation
                        $stream.WriteLine("y")
                        Start-Sleep -Seconds 2
                        $confirmOutput = $stream.Read()
                        Write-Host "Confirmation output: $confirmOutput"
                        if ($confirmOutput -match "system is going down|system halt") {
                            Write-Host "Shutdown command confirmed and executed successfully."
                        } else {
                            Write-Error "Unexpected response after confirmation. Output: $confirmOutput"
                        }
                    } else {
                        Write-Error "Did not receive expected shutdown confirmation prompt. Output: $shutdownOutput"
                    }
                }
            }
            finally {
                if ($stream) {
                    $stream.Dispose()
                }
                if ($BSTR) {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                }
            }
        }
    }
    catch {
        Write-Error "Failed to execute shutdown command: $_"
        Write-Host "Error Details: $($_.Exception.Message)"
        if ($_.Exception.InnerException) {
            Write-Host "Inner Exception: $($_.Exception.InnerException.Message)"
        }
    }
    finally {
        if ($SSHSession) {
            Remove-SSHSession -SessionId $SSHSession.SessionId -ErrorAction SilentlyContinue | Out-Null
        }
    }
}
 
# Confirmation prompt if -Force is not used
if (-not $Force) {
    $confirmation = Read-Host "Are you sure you want to shutdown the firewall at $FirewallIP? (Y/N)"
    if ($confirmation -ne 'Y') {
        Write-Host "Operation cancelled by user."
        exit
    }
}
 
# Execute shutdown
Send-ShutdownCommand -IP $FirewallIP -User $Username -Pass $Password
