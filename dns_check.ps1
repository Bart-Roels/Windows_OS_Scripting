# Get subnets from eth0 adapter
$eth0 = Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4
$subnet = $eth0.IPAddress + "/" + $eth0.PrefixLength

# Calculate the network address
$networkAddress = (Get-NetIPAddress -AddressFamily IPv4 -IPAddress $eth0.IPAddress).IPAddress
$subnetMask = ([System.Net.IPAddress]::Parse($subnet)).GetAddressBytes()
$networkAddressBytes = @()
for ($i = 0; $i -lt 4; $i++) {
    $networkAddressBytes += [byte]($networkAddress.GetAddressBytes()[$i] -band $subnetMask[$i])
}
$networkAddress = [System.Net.IPAddress]::new($networkAddressBytes)

# Set primary DNS server to itself & delete secondary DNS server
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $eth0.IPAddress
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $eth0.IPAddress -ResetServerAddresses

# Add new reverse lookup zone: Primary zone, replication domain, Ipv4 reverse lookup zone, Reverse lookup zone name --> Set networkID, Dynamic updates --> Secure only
Add-DnsServerPrimaryZone -Name $networkAddress -ZoneType "Reverse" -DynamicUpdate "Secure" -ReplicationScope "Domain"

# Make sure the zone is active
Set-DnsServerPrimaryZone -Name $networkAddress -Active

# Force pointers apearing in that zone (reverse lookup zone) (ps command)
Set-DnsServerSetting -ZoneName $networkAddress -EnablePtrUpdate $true






