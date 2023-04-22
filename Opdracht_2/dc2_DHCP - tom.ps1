#
# Install DHCP Server Role on DC2 
#
$secondDC = "win00-DC2"
$Credential = $env:USERNAME
$domainCredential = "$env:USERDOMAIN\$Credential"
$UserDNSDomain = $env:USERDNSDOMAIN.tolower()

$DNSServers = @("192.168.1.3", "192.168.1.2")
$Failover = "DC1-DC2-Failover"
$scopes = @("192.168.1.0")
$secret = "sEcReT"

$remoteSession = New-PSSession -ComputerName $secondDC -Credential $domainCredential

Invoke-Command -Session $remoteSession -Scriptblock {

    $eth0 = Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -match "802.3" -and $_.status -eq "up" }
    $ip = $eth0 | Get-NetIPAddress -AddressFamily IPv4

    $WindowsFeature = "DHCP"
    if (Get-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME | Where-Object { $_.installed -eq $false }) {
        Write-Output "Installing $WindowsFeature ..."
        Install-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME -IncludeManagementTools
    }
    else {
        Write-Output "$WindowsFeature already installed ..."
    }

    #
    # Authorizing DHCP server in AD
    #

    if (Get-DhcpServerInDC | Where-Object { $_.IPAddress -match $ip.IPAddress }) {
        Write-Output "DHCP server already authorized!"
    }
    else {
        Write-Output "Authorizing DHCP server in AD ..."
    
        Add-DhcpServerInDC -IPAddress $ip.ipaddress -DnsName $args[2]

        #Notify Server Manager that post-install DHCP configuration is complete

        Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2
    }

    Set-DhcpServerv4OptionValue `
        -ComputerName $args[0] `
        -DnsServer $args[1] `
        -DNSDomain $args[2] `
        -Force
 
} -ArgumentList $secondDC, $DNSServers, $UserDNSDomain

Add-DhcpServerv4Failover -ComputerName "$env:COMPUTERNAME.$env:USERDNSDOMAIN" -Name $Failover -PartnerServer "$secondDC.$env:USERDNSDOMAIN" -ScopeId $scopes -SharedSecret $secret

Invoke-DhcpServerv4FailoverReplication -ComputerName "$env:COMPUTERNAME.$env:USERDNSDOMAIN" -Name $Failover -Force
