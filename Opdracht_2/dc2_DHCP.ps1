# Step 1: Install DHCP Server role if necessary
$role = Get-WindowsFeature -Name DHCP
if ($role.Installed -ne $true) {
    Install-WindowsFeature -Name DHCP -IncludeManagementTools
}

# Step 2: Authorize DHCP server to give out IP addresses
Add-DhcpServerInDC

# Step 3: Configure DHCP server as load balance partner                     
$partner = "192.168.1.2"
Add-DhcpServerv4Failover -ComputerName $env:COMPUTERNAME -PartnerServer $partner -Mode LoadBalance -LoadBalancePercent 60 -Name "DHCP Failover"

# Step 4: Configure DNS load balancing
$dns1 = "192.168.1.2"
$dns2 = "192.168.1.3"
Set-DhcpServerv4OptionValue -OptionId 006 -Value $dns1, $dns2 -DnsDomain intranet.mct.be

# Step 5: Remove warning in Server Manager
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name DoNotShowFirstRunNetworkWarning -Value 1
  
