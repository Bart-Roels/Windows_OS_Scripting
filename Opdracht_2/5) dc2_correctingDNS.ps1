#
# Correcting the DNS servers on the active ethernet (802.3) network adapter, remotely on DC2
#

$DNSServers=@("192.168.1.3", "192.168.1.2")

$secondDC="win00-DC2"
$Credential=$env:USERNAME
$domainCredential="$env:USERDOMAIN\$Credential"

$remoteSession=New-PSSession -ComputerName $secondDC -Credential $domainCredential

Invoke-Command -Session $remoteSession -Scriptblock {

$eth0=Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -match "802.3"-and $_.status -eq "up"}
$eth0_ip=Get-NetIPInterface -InterfaceIndex $eth0.ifIndex -AddressFamily IPv4
$eth0_ip | Set-DnsClientServerAddress -ServerAddresses $args
 
} -ArgumentList $DNSServers

