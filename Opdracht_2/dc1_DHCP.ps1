### Imports
Add-Type -AssemblyName Microsoft.VisualBasic

# YOU HAVE TO ADD TO RUN THIS SCRIPT --> Import-Module ActiveDirectory 
# This is because the script contains the Add-ADReplicationSubnet cmdlet, which is not available in the ActiveDirectory module by default.
# https://www.thatlazyadmin.com/2017/05/08/adding-subnets-active-directory-sites-and-services-powershell/
# https://stackoverflow.com/questions/17548523/the-term-get-aduser-is-not-recognized-as-the-name-of-a-cmdlet

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
    
    try {
        # Check if PrefixLength is within the valid range
        if ($PrefixLength -lt 0 -or $PrefixLength -gt 32) {
            throw "PrefixLength must be between 0 and 32."
        }
        
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
    catch {
        Write-Error $_.Exception.Message
    }
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

    try {
        # Validate IPAddress and SubnetMask inputs
        if (-not [IPAddress]::TryParse($IPAddress, [ref]$null) -or -not [IPAddress]::TryParse($SubnetMask, [ref]$null)) {
            throw "Invalid IPAddress or SubnetMask value."
        }

        # Convert IPAddress and SubnetMask inputs to IPAddresses
        $ip = [IPAddress]::Parse($IPAddress)
        $subnet = [IPAddress]::Parse($SubnetMask)
        $networkAddressBytes = [byte[]]::new(4)

        # Calculate network address
        for ($i = 0; $i -lt 4; $i++) {
            $networkAddressBytes[$i] = [byte]($ip.GetAddressBytes()[$i] -band $subnet.GetAddressBytes()[$i])
        }

        $networkAddress = [IPAddress]$networkAddressBytes
        return $networkAddress
    }
    catch {
        Write-Error $_.Exception.Message
    }
}



### MAIN SCRIPT 

try {
    # Prompt user for site name
    $siteName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the first site name (e.g. site1)", "Site name")

    # Get subnets from eth0 adapter
    $adpt = Get-NetIPAddress -InterfaceAlias "Ethernet0" -AddressFamily IPv4 
    if (!$adpt) {
        throw "Could not retrieve IPv4 address information for Ethernet0 adapter"
    }

    # Prefix length
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
    $defaultSite = Get-ADReplicationSite -Identity "Default-First-Site-Name" -ErrorAction Stop
    if (!$defaultSite) {
        throw "Could not find Default-First-Site-Name in Active Directory"
    }
    $defaultSite | Rename-ADObject -NewName $siteName -ErrorAction Stop
    New-ADReplicationSubnet -Name $networkAddressWithMask -Site $siteName -ErrorAction Stop

    # Check if DHCP Server Role is installed, if not install it
    $DHCPRole = Get-WindowsFeature -Name DHCP -ErrorAction SilentlyContinue
    if (!$DHCPRole) {
        Install-WindowsFeature -Name DHCP -IncludeManagementTools -ErrorAction Stop
    }

    # Authorize DHCP server to give out IP addresses
    Add-DhcpServerInDC -ErrorAction Stop

    # Remove DHCP authorization warning
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\dhcp\Parameters" -Name "EnableWarning" -Value 1 -ErrorAction Stop

    # Prompt user for DHCP scope details
    $ScopeName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the scope name for DHCP", "Scope name")
    $ScopeDescription = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the scope description for DHCP", "Scope description")
    $startRange = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the startrange for DHCP (add all ip's in range and then exclude)", "start range")
    $endRange = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the endrange for DHCP", "End range")
    $subnetMask = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the subnet mask for DHCP", "Subnet mask")
    $startExcludedRange = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the start excluded range for DHCP", "Start excluded range")
   


    # Ip range 192.168.1.1 --> Pfsense
    # Ip range 192.168.1.1 , 192.168.1.254 --> Pfsense + 253 clients
    # Exclude 192.168.1.1 , 192.168.1.10

    # Check if excluded range is empty
    if ($startExcludedRange -ne "" -and $endExcludedRange -ne "") {
        # Create DHCP scope
        Add-DhcpServerv4Scope -Name $ScopeName -StartRange $startRange -EndRange $endRange -SubnetMask $subnetMask -Description $ScopeDescription 

        # Get DHCP scope by name
        $scope = Get-DhcpServerv4Scope -ComputerName "DC1" 

        if ($scope -ne $null) {
            # Get DHCP scope ID
            $scopeId = $scope.ScopeId
            # Add exclusion range to DHCP scope
            Add-Dhcpserverv4ExclusionRange -ScopeId $scopeId -StartRange $startExcludedRange -EndRange $endExcludedRange
        }
        else {
            Write-Host "Could not find DHCP scope with name $ScopeName"
        }
    }
    else {
        # Create DHCP scope
        Add-DhcpServerv4Scope -Name $ScopeName -StartRange $startRange -EndRange $endRange -SubnetMask $subnetMask -Description $ScopeDescription
    }

    # Set DHCP options
    # Default gateway
    $defaultGateway = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the default gateway for DHCP", "Default gateway")
    Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 3 -Value $defaultGateway

    # Set DNS server
    Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 6 -Value $adpt.IPAddress

    # Activate scope
    Set-DhcpServerv4Scope -ScopeId $scopeId -State Active

    # Ask for a reboot (y/n)
    if (Read-Host "The server must be rebooted for the changes to take effect. Do you want to reboot now? (Y/N)" -eq "Y") {
        Restart-Computer -Force
    }
}
catch {
    Write-Error $_.Exception.Message
}




