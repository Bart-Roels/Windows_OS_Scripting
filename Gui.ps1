Add-Type -AssemblyName System.Windows.Forms


# FORM
$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Settings"
$form.Size = New-Object System.Drawing.Size(350,300)
$form.StartPosition = "CenterScreen"

$labelHostname = New-Object System.Windows.Forms.Label
$labelHostname.Text = "Hostname:"
$labelHostname.Location = New-Object System.Drawing.Point(10,20)
$labelHostname.AutoSize = $true
$form.Controls.Add($labelHostname)

$textBoxHostname = New-Object System.Windows.Forms.TextBox
$textBoxHostname.Location = New-Object System.Drawing.Point(120,20)
$textBoxHostname.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($textBoxHostname)

$labelIPAddress = New-Object System.Windows.Forms.Label
$labelIPAddress.Text = "IP Address:"
$labelIPAddress.Location = New-Object System.Drawing.Point(10,50)
$labelIPAddress.AutoSize = $true
$form.Controls.Add($labelIPAddress)

$textBoxIPAddress = New-Object System.Windows.Forms.TextBox
$textBoxIPAddress.Location = New-Object System.Drawing.Point(120,50)
$textBoxIPAddress.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($textBoxIPAddress)

$labelSubnetMask = New-Object System.Windows.Forms.Label
$labelSubnetMask.Text = "Subnet Mask:"
$labelSubnetMask.Location = New-Object System.Drawing.Point(10,80)
$labelSubnetMask.AutoSize = $true
$form.Controls.Add($labelSubnetMask)

$textBoxSubnetMask = New-Object System.Windows.Forms.TextBox
$textBoxSubnetMask.Location = New-Object System.Drawing.Point(120,80)
$textBoxSubnetMask.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($textBoxSubnetMask)

$labelDefaultGateway = New-Object System.Windows.Forms.Label
$labelDefaultGateway.Text = "Default Gateway:"
$labelDefaultGateway.Location = New-Object System.Drawing.Point(10,110)
$labelDefaultGateway.AutoSize = $true
$form.Controls.Add($labelDefaultGateway)

$textBoxDefaultGateway = New-Object System.Windows.Forms.TextBox
$textBoxDefaultGateway.Location = New-Object System.Drawing.Point(120,110)
$textBoxDefaultGateway.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($textBoxDefaultGateway)

$labelDNSServers = New-Object System.Windows.Forms.Label
$labelDNSServers.Text = "DNS Servers:"
$labelDNSServers.Location = New-Object System.Drawing.Point(10,140)
$labelDNSServers.AutoSize = $true
$form.Controls.Add($labelDNSServers)

$textBoxDNSServers = New-Object System.Windows.Forms.TextBox
$textBoxDNSServers.Location = New-Object System.Drawing.Point(120,140)
$textBoxDNSServers.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($textBoxDNSServers)

$buttonOK = New-Object System.Windows.Forms.Button
$buttonOK.Location = New-Object System.Drawing.Point(120,190)
$buttonOK.Size = New-Object System.Drawing.Size(75,23)
$buttonOK.Text = "OK"
$buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $buttonOK
$form.Controls.Add($buttonOK)

# LOGIC

$buttonOK.Add_Click({
    # Set the logical hostname
    $logicalHostname = $textBoxHostname.Text
    # Set the hostname to the specified value
    Rename-Computer -NewName $logicalHostname -Restart
    
    # Configure static IP and DNS settings
    $ipAddress = $textBoxIPAddress.Text
    $subnetMask = $textBoxSubnetMask.Text
    $defaultGateway = $textBoxDefaultGateway.Text
    $dnsServers = $textBoxDNSServers.Text -split ","
    
    $adapter = Get-NetAdapter | Where-Object {$_.InterfaceAlias -eq "Ethernet"} # Modify this to match your adapter name
    $adapter | Set-NetIPInterface -Dhcp Disabled
    $adapter | New-NetIPAddress -IPAddress $ipAddress -PrefixLength 24 -DefaultGateway $defaultGateway
    $adapter | Set-DnsClientServerAddress -ServerAddresses $dnsServers
    
    # Set timezone to local timezone
    $localTimeZone = [System.TimeZoneInfo]::Local
    Set-TimeZone -Id $localTimeZone.Id
    
    # Enable Remote Desktop
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    
    # Disable IE Enhanced Security Configuration
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -Name "IsInstalled" -Value 0 -Force
    
    # Set view to 'Small icons' in Control Panel
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel' -Name 'AllItemsIconView' -Value 1 -Force
    
    # Enable file extensions in Windows Explorer
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Force
    
})


# FUNCTIONS

function Validate-IPAddress {
    param (
        [string]$ipAddress
    )

    try {
        [void][System.Net.IPAddress]::Parse($ipAddress)
        return $true
    }
    catch {
        return $false
    }
}

# SHOW FORM

# Display the form and wait for the user to interact with it
$form.ShowDialog()
