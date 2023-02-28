# Prompt user for input
$IPAddress = Read-Host "Enter IP address (e.g. 192.168.1.100)"
$SubnetMask = Read-Host "Enter subnet mask (e.g. 255.255.255.0)"
$Gateway = Read-Host "Enter default gateway (e.g. 192.168.1.1)"
$InterfaceAlias = Read-Host "Enter interface alias (e.g. Ethernet)"

# Convert subnet mask to byte value and set IPv4 network settings using the input
$PrefixLength = (ConvertTo-Byte -InputObject $SubnetMask.Split(".")[-1])
Set-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $Gateway

# Set interface operational status and DNS server addresses using the input
Set-NetIPInterface -InterfaceAlias $InterfaceAlias -InterfaceOperationalStatus Up ` -DnsServerAddresses ($DNSServers -split ',')



# Disable ipv6
Set-NetIPInterface -InterfaceAlias $adapter -Forwarding Enabled -Dhcp Enabled -AddressFamily IPv6 -InterfaceMetric 1 -InterfaceIndex 1 -InterfaceOperationalStatus Up -InterfaceAlias $adapter -InterfaceDescription $adapter -InterfaceT

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
