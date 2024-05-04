$user_agent = "Mozilla/5.0 (Windows NT; Windows NT 6.1; en-US) WindowsPowerShell/3.0"
$urls = @( 'https://cpdbl.net/lists/etknown.list',
    'https://feodotracker.abuse.ch/downloads/ipblocklist.txt',
    'https://cpdbl.net/lists/tor-exit.list',
    'https://cpdbl.net/lists/bruteforce.list',
    'https://cpdbl.net/lists/blocklistde-all.list',
    'https://cpdbl.net/lists/talos.list',
    'https://cpdbl.net/lists/sslblock.list'
)

$logFile = ".\get_suspicious_ips_log"
$tmpIPs = ".\tmp_IP"
$IPs = ".\IPs"

function Handle-Error {
    param(
        [string]$ErrorMessage
    )
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
}
function Write-Log {
    param(
        [string]$Message
    )
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    $LogEntry | Out-File -FilePath $logFile -Append
}
try {
    # Log script start
    Write-Log "Script started"

    if (-not (Test-Path $IPs)) {
        New-Item -ItemType File -Path $IPs | Out-Null
    }

    if (-not (Test-Path $tmpIPs)) {
        New-Item -ItemType File -Path $tmpIPs | Out-Null
    }
    
    if (-not (Test-Path $logFile)) {
        New-Item -ItemType File -Path $logFile | Out-Null
    }
    Clear-Content -Path $tmpIPs

    foreach ($url in $urls){
        try {
            $response = Invoke-RestMethod -Uri $url -UserAgent $user_agent -ErrorAction Stop
            $response | Out-File -FilePath $tmpIPs -Append 
            # Log URL invocation
            Write-Log "Invoked URL: $url"
        } catch {
            Handle-Error -ErrorMessage "Failed to retrieve data from $url . $_"
            # Log URL invocation with error
            Write-Log "Failed to retrieve data from $url : $_"
        }
    } 

    $ipRegex = [regex]"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"

    Get-Content -Path $tmpIPs | ForEach-Object {
        if ($_ -match $ipRegex) {
            $matches[0]
        }
    } | Sort-Object -Unique | Out-File -FilePath $IPs -Encoding ascii

    # Log script end
    Write-Log "Script completed successfully"
} catch {
    Handle-Error -ErrorMessage "An unexpected error occurred: $_"
    # Log unexpected error
    Write-Log "An unexpected error occurred: $_"
}
