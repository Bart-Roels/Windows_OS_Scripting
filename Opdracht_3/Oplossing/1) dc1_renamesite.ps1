#
# Renaming Default-First-Site-Name + assigning the subnet
#

$newSiteName="Kortrijk"   
$ipSubnet="192.168.1.0/24"

if ($ADReplicationSite=Get-ADReplicationSite "Default-First-Site-Name" -ErrorAction SilentlyContinue)
{
    Write-Output "Renaming Default-First-Site-Name ..."
    $ADReplicationSite | Rename-ADObject -NewName $newSiteName
    Get-ADReplicationSite $newSiteName | Set-ADReplicationSite -Description $newSiteName
    New-ADReplicationSubnet -Name $ipSubnet -Site $newSiteName -Description $newSiteName -Location $newSiteName
}
else
{
    Write-Output "Default-First-Site-Name already renamed!"
}
