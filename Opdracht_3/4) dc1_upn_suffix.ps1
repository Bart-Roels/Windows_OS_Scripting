# Import the Active Directory module
Import-Module ActiveDirectory
Add-Type -AssemblyName Microsoft.VisualBasic

# Domain name
$UPN_suffix = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the UPN suffix (e.g. intranet.mycompany.be)", "UPN suffix")

# Check if the UPN suffix already exists
if (Get-ADForest | where-Object { $_.UPNSuffixes -match $UPN_suffix }) {
    Write-Host "UPN suffix already exists"
}
else {
    # create a hashtable with the UPN suffix 
    $upnHashtable = @{
        Add = $UPN_suffix
    }
    Get-ADForest | Set-ADForest -UPNSuffixes $upnHashtable
}

#
# Change UPN suffix for all users
#

$oldUPNsuffix = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the old UPN suffix (e.g. intranet.mycompany.be)", "Old UPN suffix")
$AllUsers = Get-ADUser -Filter "UserPrincipalName -like '*$oldUPNsuffix'" -Properties UserPrincipalName -ResultSetSize $null
$AllUsers | foreach {$newUpn = $_.UserPrincipalName.Replace($oldUPNsuffix, $UPN_suffix); $_ | Set-ADUser -UserPrincipalName $newUpn}

# Print script is finished
Write-Host "Script is finished" -ForegroundColor Green

