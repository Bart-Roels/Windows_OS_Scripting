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

    # Get computername and domain
    $ComputerName=$env:COMPUTERNAME
    $UserDNSDomain=$env:USERDNSDOMAIN.ToLower()


    #
    # Reverrse lookup zone
    #

    # Get subnets from eth0 adapter
    $adpt = Get-NetIPAddress -InterfaceAlias "Ethernet0" -AddressFamily IPv4 
    if (!$adpt) {
        throw "Could not retrieve IPv4 address information for Ethernet0 adapter" -ForegroundColor Red
    }

    # Prefix length
    $prefixLength = $adpt.PrefixLength

    # Calculate network address based on IP address and subnet mask
    # Get prefix length from subnet mask
    $prefixLength = $adpt.PrefixLength
    # Get netmask from prefix length
    $netmask = CIDRToNetMask -PrefixLength $prefixLength

    # Get network address based on IP address and subnet mask
    $networkAddress = Get-NetworkAddress -InterfaceAlias "Ethernet0" -IPAddress $adpt.IPAddress -SubnetMask $netmask

    # Create DNS reverse lookup zone
    Add-DnsServerPrimaryZone -NetworkId $networkAddress -ReplicationScope "Forest" -DynamicUpdate "Secure"

    # register dns-clients --> Pointer record aangemaakt worden
    register-dnsclient


    Write-Host "DNS reverse lookup zone created for $networkAddress/$prefixLength" -ForegroundColor Green
        


    #
    # Renaming Default-First-Site-Name + assigning the subnet
    #



    # Prompt user for site name
    $newSiteName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the first site name (e.g. site1)", "Site name")

    # Network address + mask
    $networkAddressWithMask = $networkAddress.ToString() + "/" + $prefixLength.ToString()

    if ($ADReplicationSite=Get-ADReplicationSite "Default-First-Site-Name" -ErrorAction SilentlyContinue)
    {
        Write-Output "Renaming Default-First-Site-Name ..."
        $ADReplicationSite | Rename-ADObject -NewName $newSiteName
        Get-ADReplicationSite $newSiteName | Set-ADReplicationSite -Description $newSiteName
        New-ADReplicationSubnet -Name $networkAddressWithMask -Site $newSiteName -Description $newSiteName -Location $newSiteName
    }
    else
    {
        Write-Output "Default-First-Site-Name already renamed!"
    }     




    #
    # Creating DHCP scope
    #


  
    # Check if DHCP Server Role is installed, if not install it
    $WindowsFeature="DHCP"
    if (Get-WindowsFeature $WindowsFeature -ComputerName $ComputerName | Where-Object { $_.installed -eq $false })
    {
        Write-Output "Installing $WindowsFeature ..."
        Install-WindowsFeature $WindowsFeature -ComputerName $ComputerName -IncludeManagementTools
    }
    else
    {
        Write-Output "$WindowsFeature already installed ..."
    }


    #
    # Authorizing DHCP server in AD
    #


    # Get IPv4 address of eth0 adapter

    $eth0 = Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -match "802.3" -and $_.status -eq "up" }
    $ip = $eth0 | Get-NetIPAddress -AddressFamily IPv4

    # Authorize DHCP server in AD
    if (Get-DhcpServerInDC | Where-Object { $_.IPAddress -match $ip.IPAddress }) {
        Write-Output "DHCP server already authorized!"
    }
    else {
        Write-Output "Authorizing the DHCP server in AD ..."
        
        Add-DhcpServerInDC -IPAddress $ip.ipaddress -DnsName $UserDNSDomain

        #Notify Server Manager that post-install DHCP configuration is complete

        Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2
    }

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
        Add-DhcpServerv4Scope `
        -Computername $ComputerName `
        -Name $ScopeName `
        -Description $ScopeDescription `
        -StartRange $startRange `
        -EndRange $endRange `
        -SubnetMask $subnetMask `
        -LeaseDuration 8:0:0:0 `
        -State Active
    
        # Get DHCP scope by name
        $scope = Get-DhcpServerv4Scope -ComputerName $ComputerName -Name $ScopeName

        Write-Host "Scope $ScopeName created" -ForegroundColor Green
        Write-Host "Adding exclusion range $startExcludedRange - $endExcludedRange to DHCP scope $ScopeName" -ForegroundColor Green

        # Check if DHCP scope exists 
        if ($scope -ne $null) {
            # Get DHCP scope ID
            $scopeId = $scope.ScopeId
            # Add exclusion range to DHCP scope  
            Add-Dhcpserverv4ExclusionRange `
            -Computername $ComputerName `
            -ScopeID $scopeId `
            -StartRange $startExcludedRange `
            -EndRange $endExcludedRange

            Write-Host "Exclusion range $startExcludedRange - $endExcludedRange added to DHCP scope $ScopeName" -ForegroundColor Green

        }
        else {
            Write-Host "Could not find DHCP scope with name $ScopeName" -ForegroundColor Red
        }

    }
    else {

        # Info
        write-host "Excluded range is empty" -ForegroundColor Yellow

        # Create DHCP scope
        Add-DhcpServerv4Scope `
        -Computername $ComputerName `
        -Name $ScopeName `
        -Description $ScopeDescription `
        -StartRange $startRange `
        -EndRange $endRange `
        -SubnetMask $subnetMask `
        -LeaseDuration 8:0:0:0 `
        -State Active
      
        # Output DHCP scope created
        Write-Host "Scope $ScopeName created" -ForegroundColor Green
    }

    # Set DHCP options
    # Default gateway
    $defaultGateway = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the default gateway for DHCP", "Default gateway")

    # Check if default gateway is empty and correct ip format otherwise ask again
    while ($defaultGateway -eq "" -or $defaultGateway -notmatch "\b(?:\d{1,3}\.){3}\d{1,3}\b") {
        $defaultGateway = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the default gateway for DHCP", "Default gateway")
    }

    # Set default gateway
    Set-DhcpServerv4OptionValue `
    -ComputerName $ComputerName `
    -ScopeID $scopeId `
    -Router $defaultGateway

    $DNSServers=@("192.168.1.2","192.168.1.3")
    Set-DhcpServerv4OptionValue `
    -ComputerName $ComputerName ` 
    -DnsServer $DNSServers ` 
    -DNSDomain $UserDNSDomain ` 
    -Force 

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




