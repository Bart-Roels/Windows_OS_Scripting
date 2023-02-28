$adapter = Read-Host "Enter the name of the network adapter you want to configure"
$ipAddress = Read-Host "Enter the IP address for this server (e.g. 192.168.0.10)"
$subnetMask = Read-Host "Enter the subnet mask for this server (e.g. 255.255.255.0)"
$defaultGateway = Read-Host "Enter the default gateway for this server"
$dnsServers = Read-Host "Enter the DNS server addresses (separated by commas)"

$prefixLength = Convert-NetmaskToPrefixLength $subnetMask

New-NetIPAddress -InterfaceAlias $adapter -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $defaultGateway
Set-DnsClientServerAddress -InterfaceAlias $adapter -ServerAddresses $dnsServers.Split(',')

# Choose the timezone
Set-TimeZone -Name "Central European Standard Time"

# Enable remote desktop access
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Disable IE Enhanced Security Setting
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
$ieParams = @{
    Path  = $AdminKey
    Name  = "IsInstalled"
    Value = 0
}
Set-ItemProperty @ieParams
$ieParams.Path = $UserKey
Set-ItemProperty @ieParams
Stop-Process -Name Explorer

# Set the Control Panel view to Small icons
If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" -Name "StartupPage" -Type DWord -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" -Name "AllItemsIconView" -Type DWord -Value 1

# Notify user and restart after 10 seconds
# Write-Host "The server will restart in 10 seconds."
# Start-Sleep -Seconds 10
# Restart-Computer -Force
