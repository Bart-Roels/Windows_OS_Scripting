### FUNCTIONS

# Cidr to netmask
Function CIDRToNetMask {
    # Define function and set metadata for parameters
    [CmdletBinding()]
    Param(
        # The CIDR prefix length to convert to a subnet mask
        [ValidateRange(0, 32)]
        [int16]$PrefixLength = 0
    )
    
    # Create a binary string representing the subnet mask
    $bitString = ('1' * $PrefixLength).PadRight(32, '0')
  
    # Create a new StringBuilder object to store the subnet mask in dotted-decimal notation
    $strBuilder = New-Object -TypeName Text.StringBuilder
  
    # Iterate over the 32-bit string in 8-bit chunks, convert each chunk to an integer, and append it to the StringBuilder
    for ($i = 0; $i -lt 32; $i += 8) {
        $8bitString = $bitString.Substring($i, 8)
        [void]$strBuilder.Append("$([Convert]::ToInt32($8bitString,2)).")
    }
  
    # Convert the StringBuilder to a string and remove the trailing period, then return the subnet mask
    $strBuilder.ToString().TrimEnd('.')
}

# Calculate network address based on IP address and subnet mask
function Get-NetworkAddress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [string]$IPAddress,

        [Parameter(Mandatory = $true)]
        [string]$SubnetMask
    )

    $ip = [IPAddress]::Parse($IPAddress)
    $subnet = [IPAddress]::Parse($SubnetMask)
    $networkAddressBytes = [byte[]]::new(4)

    for ($i = 0; $i -lt 4; $i++) {
        $networkAddressBytes[$i] = [byte]($ip.GetAddressBytes()[$i] -band $subnet.GetAddressBytes()[$i])
    }

    $networkAddress = [IPAddress]$networkAddressBytes
    return $networkAddress
}


### MAIN SCRIPT 

# Get subnets from eth0 adapter
$adpt = Get-NetIPAddress -InterfaceAlias "Ethernet0" -AddressFamily IPv4 

# Set primary DNS server to itself & delete secondary DNS server
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses $adpt.IPAddress

# Calculate network address based on IP address and subnet mask
# Get prefix length from subnet mask
$prefixLength = $adpt.PrefixLength
# Get netmask from prefix length
$netmask = CIDRToNetMask -PrefixLength $prefixLength

# Get network address based on IP address and subnet mask
$networkAddress = Get-NetworkAddress -InterfaceAlias "Ethernet0" -IPAddress $adpt.IPAddress -SubnetMask $netmask

# Use the first 3 octets of the network address as the network ID
$networkId = $networkAddress.GetAddressBytes()[0..2] -join "."

# Create DNS reverse lookup zone
Add-DnsServerPrimaryZone -NetworkId $networkId -ReplicationScope "Domain" -DynamicUpdate "Secure"







