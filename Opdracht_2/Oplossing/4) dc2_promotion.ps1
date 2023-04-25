#
# Promoting DC2 to become an additional DC in the existing Windows domain
#
$ComputerName=$env:COMPUTERNAME
$Credential=$env:USERNAME
$domainCredential="$env:USERDOMAIN\$Credential"
$secondDC="win00-DC2"
$UserDNSDomain=$env:USERDNSDOMAIN.tolower()

$remoteSession=New-PSSession -ComputerName $secondDC -Credential $domainCredential

Invoke-Command -Session $remoteSession -Scriptblock {

    #
    # Installing AD Domain Services - ADDS
    #

    $WindowsFeature="AD-Domain-Services"
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
    # Create Domain Controller
    #
    Install-ADDSDomainController `
    -DomainName $args[0] `
    -InstallDns:$true `
    -Credential (Get-Credential $args[1]) `
    -Force:$true

} -ArgumentList $UserDNSDomain, $domainCredential
