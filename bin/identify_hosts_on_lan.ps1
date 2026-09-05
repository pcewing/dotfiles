# identify_hosts_on_lan.ps1
# Description: Scans a subnet in parallel using PowerShell 7+ and resolves hostnames.

# Requires -Version 7.0

# Define the subnet prefix (change this if your LAN uses a different range)
$SubnetPrefix = "192.168.1"

Write-Host "Scanning network ${SubnetPrefix}.1 to ${SubnetPrefix}.254 in parallel..." -ForegroundColor Cyan

# 1. Scan the network utilizing parallel threads
$ActiveHosts = 1..254 | ForEach-Object -Parallel {
    # Using $using: to pull the variable from the parent scope into the parallel thread
    $IP = "$($using:SubnetPrefix).$_"
    
    # Ping the IP address
    $Ping = Test-Connection -ComputerName $IP -Count 1 -Delay 15 -ErrorAction SilentlyContinue
    
    # If successful, pass the IP object down the pipeline
    if ($Ping -and $Ping.Status -eq "Success") {
        [PSCustomObject]@{
            IPAddress = $IP
        }
    }
} -ThrottleLimit 50 # Adjust throttle limit based on network/system capacity

# Check if any hosts were found
if ($null -eq $ActiveHosts) {
    Write-Host "No active hosts discovered on the network." -ForegroundColor Yellow
    Exit
}

Write-Host "`nDiscovered $($ActiveHosts.Count) active host(s). Resolving hostnames..." -ForegroundColor Cyan

# 2. Dynamically resolve hostnames for discovered IPs
$Results = $ActiveHosts | ForEach-Object {
    $TargetIP = $_.IPAddress
    
    # Attempt to resolve the DNS/NetBIOS name
    $DnsResolve = Resolve-DnsName -Name $TargetIP -ErrorAction SilentlyContinue
    
    if ($DnsResolve) {
        # Select the host name (handles arrays by taking the first match)
        $HostName = ($DnsResolve.NameHost)[0]
    } else {
        $HostName = "Unknown (No DNS Record)"
    }

    # Construct the final output object
    [PSCustomObject]@{
        IPAddress = $TargetIP
        HostName  = $HostName
    }
}

# 3. Output the final structured results to the console
$Results | Format-Table -AutoSize
