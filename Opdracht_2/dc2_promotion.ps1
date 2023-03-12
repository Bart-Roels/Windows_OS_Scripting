# Set the domain name and admin credentials
$domainName = "intranet.mct.be"
$adminUsername = "administrator@MCT.local"

$adminPassword = "P@ssw0rd"

# Install the AD DS role if it's not already installed
if ((Get-WindowsFeature -Name AD-Domain-Services).Installed -ne $true) {
    Install-WindowsFeature AD-Domain-Services
}

# Promote the server to a domain controller
Install-ADDSDomainController `
    -DomainName $domainName `
    -SafeModeAdministratorPassword (ConvertTo-SecureString -String $adminPassword -AsPlainText -Force) `
    -InstallDNS:$true `
    -Force:$true

