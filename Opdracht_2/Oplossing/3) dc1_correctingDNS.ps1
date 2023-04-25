#
# Correcting the DNS servers on the active ethernet (802.3) network adapter
#

$DNSServers = @("192.168.1.2", "192.168.1.3")

$eth0 = Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -match "802.3" -and $_.status -eq "up" }
if (!$eth0) {
    Write-Output "No connected ethernet interface found ! Please connect cable ..."
    exit(1)
}

$eth0_ip = Get-NetIPInterface -InterfaceIndex $eth0.ifIndex -AddressFamily IPv4
# Set DNS servers
$eth0_ip | Set-DnsClientServerAddress -ServerAddresses $DNSServers
