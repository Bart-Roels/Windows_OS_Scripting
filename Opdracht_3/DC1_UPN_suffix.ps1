# Import the Active Directory module
Import-Module ActiveDirectory

# Set the new UPN suffix
$newUPNSuffix = "mct.be"

# Get the current UPN suffixes for the domain
$domain = Get-ADDomain
$currentUPNSuffixes = $domain.UPNSuffixes

# Check if the new UPN suffix already exists
if ($currentUPNSuffixes -contains $newUPNSuffix) {
    Write-Output "The UPN suffix $newUPNSuffix already exists."
} else {
    # Add the new UPN suffix to the domain
    $currentUPNSuffixes += $newUPNSuffix
    Set-ADDomain -UPNSuffixes $currentUPNSuffixes

    Write-Output "The UPN suffix $newUPNSuffix has been added to the domain."
}
