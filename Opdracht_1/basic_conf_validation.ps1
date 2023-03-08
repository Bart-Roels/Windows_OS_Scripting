# Prompt user for input and set variables
$ComputerName = Read-Host "Enter the computer name (e.g. server1)"

# Prompt user for ip and validate it
do {
    $validIP = $true
    $IPAddress = Read-Host "Enter IP address (e.g. 192.168.1.100)"
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
    $validGateway = $true
    $Gateway = Read-Host "Enter default gateway (e.g. 192.168.1.1)"
    try {
        [System.Net.IPAddress]::Parse($Gateway) | Out-Null
    }
    catch {
        Write-Host "Invalid default gateway entered. Please enter a valid default gateway."
        $validGateway = $false
    }
} until ($validGateway)

# Ask for the subnet prefix and dns servers
$Prefix = Read-Host "Enter subnet prefix (e.g. 24)"
$dnsServer1 = Read-Host "Enter the primary DNS server for this server"
$dnsServer2 = Read-Host "Enter the secondary DNS server for this server"


# Set IPv4 network settings using the input
New-NetIPAddress –IPAddress $IPAddress  -DefaultGateway $Gateway -PrefixLength $Prefix -InterfaceIndex (Get-NetAdapter).InterfaceIndex

# Disable IPv6
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\" -Name "DisabledComponents" -Value "0xffffffff" -Type DWORD

# Set DNS server addresses using the input
Set-DNSClientServerAddress –InterfaceIndex (Get-NetAdapter).InterfaceIndex –ServerAddresses $dnsServer1, $dnsServer2

# Choose the timezone
Set-TimeZone -Name 'Romance Standard Time' -PassThru

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

