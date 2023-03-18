# Import the Active Directory module
Import-Module ActiveDirectory

if(Get-ADForrest | where-Object{ $_.UPNSuffixes -match $UPN_suffix })
{
    Write-Host "UPN suffix already exists"
}
else {
    Get-ADForrest | Set-ADForrest -UPNSuffixes $UPN_suffix
    
}