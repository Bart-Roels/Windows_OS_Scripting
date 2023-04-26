#
# Install the Certificate Authority of the Active Directory Cerficate Services
#

$WindowsFeature="ADCS-Cert-Authority"
if (Get-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME | Where-Object { $_.installed -eq $false })
{
    Write-Output "Installing $WindowsFeature ..."
    Install-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME -IncludeManagementTools
}
else
{
    Write-Output "$WindowsFeature already installed on $env:COMPUTERNAME ..."
}


#
# Configure a default Domain CA
#

$Credential=get-credential -Credential "$env:USERDOMAIN\$env:USERNAME"

$CryptoProviderName="RSA#Microsoft Software Key Storage Provider"
$KeyLength=4096
$HashAlgorithmName=”SHA256”
$ValidityPeriod=”Years”
$ValidityPeriodUnits=10

Install-AdcsCertificationAuthority -CAType EnterpriseRootCa -Credential $Credential -CryptoProviderName $CryptoProviderName-KeyLength $KeyLength -HashAlgorithmName $HashAlgorithmName -ValidityPeriod $ValidityPeriod -ValidityPeriodUnits $ValidityPeriodUnits -Confirm:$False | Out-Null



#
# Install Network Policy and Access Services
#

$WindowsFeature="NPAS"
if (Get-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME | Where-Object { $_.installed -eq $false })
{
    Write-Output "Installing $WindowsFeature ..."
    Install-WindowsFeature $WindowsFeature -ComputerName $env:COMPUTERNAME -IncludeManagementTools
}
else
{
    Write-Output "$WindowsFeature already installed on $env:COMPUTERNAME ..."
}


#
# Registering NPS in Active Directory by adding DC1 to the group ‘RAS and IAS Servers’
#
$Identity="RAS and IAS Servers"
$Members=Get-ADComputer -identity $env:COMPUTERNAME

try {
    Add-ADGroupMember -Identity $Identity -Members $Members
    Write-Output "Adding $Members to $Identity ..."
} catch {
    Write-Output "The NPS server $Members is already member of $Identity ..."
}


#
# Exporting the NPS Configuration
#
$File="NPSConfiguration.xml"

Write-Host "Exporting the NPS Configuration to the XML-file $File ... " -Foreground Cyan
Export-NpsConfiguration $File

#
# Importing the NPS Configuration
#
try {
    $File="NPSConfiguration.xml"
    Import-NpsConfiguration $File
    Write-Host "Importing the NPS Configuration from the XML-file $File ... " -Foreground Cyan
} catch {
    Write-Host "Unable to open the file $File ... " -Foreground Red
}


#
# Creating RADIUS clients
#
try {
    $File=".\Radiusclients.csv"
    $RadiusClients=Import-Csv $File -Delimiter ";" -ErrorAction Stop
    Foreach ($RadiusClient in $RadiusClients)
    { 
	    $IP=$RadiusClient.IP
	    $Name=$RadiusClient.Name
	    $Secret=$RadiusClient.Secret

        try {
            New-NpsRadiusClient -Address $IP -Name $Name -SharedSecret $Secret | Out-Null
            Write-Host "Creating RADIUS Client $Name with IP address $IP and secret $Secret ..."
        } catch {
            Write-Host "RADIUS Client $Name with IP address $IP and secret $Secret already exists ..."
        }
    }
} catch {
    Write-Host "Unable to open the file $File ... " -Foreground Red
}




