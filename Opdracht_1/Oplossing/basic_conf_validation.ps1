
#
# Get the active ethernet (802.3) network adapter and set the IP configuration
#

$eth0=Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -match "802.3"-and $_.status -eq "up"}
$eth0_ip = Get-NetIPInterface -InterfaceIndex $eth0.ifIndex -AddressFamily IPv4

if (!$eth0)
{
    Write-Output "No connected ethernet interface found ! Please connect cable ..."
    exit(1)
}

Write-Host "Configuring network interface $($eth0.Name) ..." -ForegroundColor Yellow


#
# Ask for IP settigs
#


# Prompt user for ip and validate it
do {
    $validIP = $true
    $IPAddress = Read-Host "Enter IP address (e.g. 192.168.1.2)"
    try {
        [System.Net.IPAddress]::Parse($IPAddress) | Out-Null
    }
    catch {
        Write-Host "Invalid IP address entered. Please enter a valid IP address." 
        $validIP = $false
    }
} until ($validIP)

# Prompt user for input ip settings gateway and validate it
do {
    $validIP = $true
    $Gateway = Read-Host "Enter gateway (e.g. 192.168.1.1)"
    try {
        [System.Net.IPAddress]::Parse($Gateway) | Out-Null
    }
    catch {
        Write-Host "Invalid IP address entered. Please enter a valid IP address." 
        $validIP = $false
    }
} until ($validIP)

# Ask for the subnet prefix and dns servers and validate them
$Prefix = Read-Host "Enter subnet prefix (e.g. 24)"
$dnsServer1 = Read-Host "Enter the primary DNS server for this server"
$dnsServer2 = Read-Host "Enter the secondary DNS server for this server"


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

# Set DNS servers
$eth0 | Set-DnsClientServerAddress -ServerAddresses $dnsServer1,$dnsServer2 | Out-Null

#
# Set Time Zone by Id
#
# List all available time zones - Get-TimeZone -ListAvailable
#
$currentTimeZone=Get-TimeZone
$newTimeZoneId="Romance Standard Time"

if ($currentTimeZone.Id -eq $newTimeZoneId)
{
    Write-Output "Time zone $currentTimeZone.Id already set!"
}
else
{
    	Write-Output "Setting Time Zone to $newTimeZoneId …"
	Set-TimeZone -Id $newTimeZoneId -PassThru
}


#
# Enabling Remote Desktop (toggling script)
#
$remoteDesktop=get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"-Name "fDenyTSConnections"
if ($remoteDesktop.fDenyTSConnections)
{
    Write-Output "Enabling RDP ..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"-Name "fDenyTSConnections"-Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
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


#
# Rename the current computer
#
$currentComputerName=$env:COMPUTERNAME
$newComputerName = Read-Host "Enter the computer name (e.g. server1)"

if ($currentComputerName -eq $newComputerName)
{
    # computer name is already set with green color
    Write-Output "Computer name $currentComputerName already set!" -ForegroundColor Green
}
else
{
    Write-Output "Renaming the computer to $newComputerName and rebooting …"
	Rename-Computer -ComputerName $currentComputerName -NewName $newComputerName -Confirm:$false
    # Say that the computer needs to be rebooted
    Write-Output "The computer needs to be rebooted. Press any key to reboot." -ForegroundColor Yellow
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Restart-Computer -Force
}




