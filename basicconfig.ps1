# Prompt for the hostname
$hostname = Read-Host "Enter the hostname for this server (e.g. FileServer01)"

# Prompt for the IP address and subnet mask
$ipAddress = Read-Host "Enter the IP address for this server (e.g. 192.168.0.10)"
$subnetMask = Read-Host "Enter the subnet mask for this server (e.g. 255.255.255.0)"
$defaultGateway = Read-Host "Enter the default gateway for this server"
$dnsServers = Read-Host "Enter the DNS servers for this server (e.g. '8.8.8.8', '8.8.4.4')"

# Set the hostname to the specified value
Rename-Computer -NewName $hostname -Restart

# Configure a static IP address
$nic = Get-NetAdapter | Where-Object { $_.Name -eq "Ethernet" }
$nic | Set-NetIPAddress -IPAddress $ipAddress -PrefixLength $subnetMask -DefaultGateway $defaultGateway
$nic | Set-DnsClientServerAddress -ServerAddresses $dnsServers

# Set the timezone to the local timezone

Set-TimeZone -Name "Central Standard Time"

# Enable remote desktop access
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Disable IE Enhanced Security Setting
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer

# Set the Control Panel view to Small icons
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" -Name "AllItemsIconView" -Value 1

# Enable file extensions in Windows Explorer
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
