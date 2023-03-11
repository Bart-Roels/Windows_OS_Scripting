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

# Use the function to get the netmask
$netmask = CIDRToNetMask -PrefixLength 24
# Print the netmask
Write-Host $netmask