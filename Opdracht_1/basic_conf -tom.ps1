# Prompt user for input and set variables
$ComputerName = Read-Host "Enter the computer name (e.g. server1)"

# Prompt user for input ip settings
$IPAddress = Read-Host "Enter IP address (e.g. 192.168.1.100)"
$Prefix = Read-Host "Enter subnet prefix (e.g. 24)"
$Gateway = Read-Host "Enter default gateway (e.g. 192.168.1.1)"
$dnsServer1 = Read-Host "Enter the primary DNS server for this server"
$dnsServer2 = Read-Host "Enter the secondary DNS server for this server"


$eth0 = Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -match "802.3" -and $_.status -eq "up" }
if (!$eth0) {
    Write-Output "No connected ethernet interface found ! Please connect cable ..."
    exit(1)
}

$eth0_ip = Get-NetIPInterface -InterfaceIndex $eth0.ifIndex -AddressFamily IPv4
#
# if DHCP is enabled
#
if ($eth0_ip.dhcp) {
    # Disable DHCP
    $eth0_ip | Set-NetIPInterface -DHCP Disabled
}

Write-Output "Configuring static IP address $IPAddress and other TCP/IP parameters ..."    
# Set IP data on the network interface
$eth0 | New-NetIPAddress -AddressFamily IPv4 -IPAddress $IPAddress -PrefixLength $Prefix -Type Unicast -DefaultGateway $Gateway | Out-Null

# Set DNS server addresses using the input
Set-DNSClientServerAddress –InterfaceIndex (Get-NetAdapter).InterfaceIndex –ServerAddresses $dnsServer1, $dnsServer2

# Choose the timezone
Set-TimeZone -Name 'Romance Standard Time' -PassThru

#
# Enabling Remote Desktop (toggling script)
#
$remoteDesktop = get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"-Name "fDenyTSConnections"
if ($remoteDesktop.fDenyTSConnections) {
    Write-Output "Enabling RDP ..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"-Name "fDenyTSConnections"-Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
}
else {
    Write-Output "Disabling RDP ..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"-Name "fDenyTSConnections"-Value 1
    Disable-NetFirewallRule -DisplayGroup "Remote Desktop"
}


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

# Set in file explorer to show hidden files
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Type DWord -Value 1
# Set in file explorer to show file extensions
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 0

# Set the computer name
Rename-Computer -NewName $ComputerName 
# Warn user that the computer needs to be restarted
Write-Host "The computer needs to be restarted to apply the changes. Press any key to restart the computer."
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Restart-Computer -Forc
