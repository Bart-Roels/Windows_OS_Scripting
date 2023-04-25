# Install the AD DS role if it's not already installed
$roles = "AD-Domain-Services", "DNS"
foreach ($role in $roles) {
    if ((Get-WindowsFeature -Name $role).Installed -ne $true) {
        Install-WindowsFeature -Name $role -IncludeManagementTools
        # Installing background green
        Write-Host "The $role role has been installed." -BackgroundColor Green
    }
    else {
        # Alread installed forgrond orange
        Write-Host "The $role role is already installed." -ForegroundColor Yellow
    }
}



# Set the domain name and admin credentials
$domainName = "intranet.mct.be"
$adminUsername = "administrator@intranet.mct.be"
$adminPassword = "P@ssw0rd"

# Promote the server to a domain controller
Install-ADDSDomainController `
    -DomainName $domainName `
    -Credential (Get-Credential $adminUsername) `
    -Force:$true


# Ask for a reboot
Write-Output "The computer needs to be rebooted. Press any key to reboot." -ForegroundColor Yellow
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Restart-Computer -Force



