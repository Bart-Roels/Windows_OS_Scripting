### Imports
Add-Type -AssemblyName Microsoft.VisualBasic

# YOU HAVE TO ADD TO RUN THIS SCRIPT --> Import-Module ActiveDirectory 
# This is because the script contains the Add-ADReplicationSubnet cmdlet, which is not available in the ActiveDirectory module by default.
# https://www.thatlazyadmin.com/2017/05/08/adding-subnets-active-directory-sites-and-services-powershell/

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

$siteName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the first site name (e.g. site1)", "Site name")

# Get subnets from eth0 adapter
$adpt = Get-NetIPAddress -InterfaceAlias "Ethernet0" -AddressFamily IPv4 
# Prfix length
$prefixLength = $adpt.PrefixLength

# Set primary DNS server to itself & delete secondary DNS server
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses $adpt.IPAddress

# Calculate network address based on IP address and subnet mask
# Get prefix length from subnet mask
$prefixLength = $adpt.PrefixLength
# Get netmask from prefix length
$netmask = CIDRToNetMask -PrefixLength $prefixLength

# Get network address based on IP address and subnet mask
$networkAddress = Get-NetworkAddress -InterfaceAlias "Ethernet0" -IPAddress $adpt.IPAddress -SubnetMask $netmask

# Create DNS reverse lookup zone
Add-DnsServerPrimaryZone -NetworkId $networkAddress -ReplicationScope "Domain" -DynamicUpdate "Secure"

# Network address + mask
$networkAddressWithMask = $networkAddress.ToString() + "/" + $prefixLength.ToString()

# Rename the 'default-first-site-name' to a meaningful name and add your subnet to it.
Add-ADReplicationSubnet -Name $networkAddressWithMask -SiteName "Default-First-Site-Name"
Rename-DnsServerPrimaryZone -Name "default-first-site-name" -NewName $siteName
