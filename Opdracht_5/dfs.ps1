# Set variables for server names and folder targets
$dc1 = "DC1"
$winxx_ms = "winxx-ms"
$winxx_dc2 = "winxx-dc2"
$recipes_target = "\\$winxx_ms\recipes"
$menus_target = "\\$winxx_dc2\menus"

# Install DFS Namespaces service on DC1
Install-WindowsFeature FS-DFS-Namespace -ComputerName $dc1

# Install DFS Replication service on all servers
Invoke-Command -ComputerName $dc1, $winxx_ms, $winxx_dc2 -ScriptBlock { Install-WindowsFeature FS-DFS-Replication }

# Create new domain DFS namespace 'CompanyInfo'
New-DfsnRoot -Path "\\$dc1\CompanyInfo" -Type DomainV2

# Create DFS link folder 'Recipes'
New-DfsnFolder -Path "\\$dc1\CompanyInfo" -Name "Recipes" -TargetPath $recipes_target

# Create DFS link folder 'Menus'
New-DfsnFolder -Path "\\$dc1\CompanyInfo" -Name "Menus" -TargetPath $menus_target

# Create DFS Replication group 'AllMenus'
New-DfsReplicationGroup -GroupName "AllMenus" -DomainName "CompanyInfo" -FolderName "Menus" -ContentPath $menus_target -MemberList $winxx_dc2, $winxx_ms -Schedule "Always"

# Force a replication sync for the group
Get-DfsrGroup -GroupName "AllMenus" | ForEach-Object { Get-DfsrMember -GroupName $_.GroupName -DomainName $_.DomainName | ForEach-Object { Sync-DfsReplicationGroup $_.GroupName $_.DomainName $_.MemberName } }

# Generate a script to undo all of the changes made
$undo_script = @"
# Remove DFS Replication group 'AllMenus'
Remove-DfsReplicationGroup -GroupName "AllMenus" -DomainName "CompanyInfo" -Force

# Remove DFS link folder 'Menus'
Remove-DfsnFolder -Path "\\$dc1\CompanyInfo" -Name "Menus"

# Remove DFS link folder 'Recipes'
Remove-DfsnFolder -Path "\\$dc1\CompanyInfo" -Name "Recipes"

# Remove DFS namespace 'CompanyInfo'
Remove-DfsnRoot -Path "\\$dc1\CompanyInfo" -Force

# Uninstall DFS Replication service on all servers
Invoke-Command -ComputerName $dc1,$winxx_ms,$winxx_dc2 -ScriptBlock {Uninstall-WindowsFeature FS-DFS-Replication}

# Uninstall DFS Namespaces service on DC1
Uninstall-WindowsFeature FS-DFS-Namespace -ComputerName $dc1
"@

# Print the undo script to the console
Write-Output $undo_script
