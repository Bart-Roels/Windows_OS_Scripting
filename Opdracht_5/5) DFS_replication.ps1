#
# Install DFS Namespaces on all participating servers
#

$secondDC="DC2"
$MemberServer="MS"

$Credential="$env:USERNAME"
$domainCredential="$env:USERDOMAIN\$Credential"
$UserDNSDomain=$env:USERDNSDOMAIN.tolower()

$WindowsFeature="FS-DFS-Replication"
if (Get-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME | Where-Object { $_.installed -eq $false })
{
    Write-Output "Installing $WindowsFeature ..."
    Install-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME -IncludeManagementTools
}
else
{
    Write-Output "$WindowsFeature already installed on $env:COMPUTERNAME ..."
}

$remoteSession=New-PSSession -ComputerName $secondDC -Credential $domainCredential
Invoke-Command -Session $remoteSession -Scriptblock {

    $WindowsFeature="FS-DFS-Replication"
    if (Get-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME | Where-Object { $_.installed -eq $false })
    {
        write-host "Installing $WindowsFeature ..."
        Install-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME -IncludeManagementTools
    }
    else
    {
        write-host "$WindowsFeature already installed on $env:COMPUTERNAME ..."
    }

}

$remoteSession=New-PSSession -ComputerName $MemberServer -Credential $domainCredential
Invoke-Command -Session $remoteSession -Scriptblock {

    $WindowsFeature="FS-DFS-Replication"
    if (Get-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME | Where-Object { $_.installed -eq $false })
    {
        write-host "Installing $WindowsFeature ..."
        Install-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME -IncludeManagementTools
    }
    else
    {
        write-host "$WindowsFeature already installed on $env:COMPUTERNAME ..."
    }

}
