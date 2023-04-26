#
# Install DFS Namespaces
#

$ComputerName=$env:COMPUTERNAME

$WindowsFeature="FS-DFS-Namespace"
if (Get-WindowsFeature $WindowsFeature -ComputerName $ComputerName | Where-Object { $_.installed -eq $false })
{
    Write-Output "Installing $WindowsFeature ..."
    Install-WindowsFeature $WindowsFeature -ComputerName $ComputerName -IncludeManagementTools
}
else
{
    Write-Output "$WindowsFeature already installed ..."
}
