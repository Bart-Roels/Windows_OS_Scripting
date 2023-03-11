Add-Type -AssemblyName Microsoft.VisualBasic

# Domain name
$domainName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the domain name (e.g. intranet.mycompany.be)", "Domain name")

# Check if the necessary role(s) is/are installed. If not, install them.
$roles = "AD-Domain-Services", "DNS"
foreach ($role in $roles) {
    if ((Get-WindowsFeature -Name $role).Installed -ne $true) {
        Install-WindowsFeature -Name $role -IncludeManagementTools
    }
}

# Add domain controller to the domain
Add-Computer -DomainName $domainName -Credential $domainAdminCreds -Restart -Force

# Promote server to secondary DC in the domain
Install-ADDSDomainController -DomainName $domainName -Credential $domainAdminCreds -Force:$true -InstallDNS:$true -NoRebootOnCompletion

# Ask for a reboot (y/n)
if (Read-Host "The server must be rebooted for the changes to take effect. Do you want to reboot now? (Y/N)" -eq "Y") {
    Restart-Computer -Force
}


