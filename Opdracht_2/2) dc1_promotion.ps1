Add-Type -AssemblyName Microsoft.VisualBasic

# Domain name
$domainName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the domain name (e.g. intranet.mycompany.be)", "Domain name")

try {

    # Check if the necessary role(s) is/are installed. If not, install them.
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


    #
    # FORREST
    #

    # Make netbios name from domain name take middle part
    $domainNetbiosName = $domainName.Split(".")[1]
    # Make sure the netbios name is not longer than 15 characters
    if ($domainNetbiosName.Length -gt 15) {
        $domainNetbiosName = $domainNetbiosName.Substring(0, 15)
    }
    # Set the domain netbios name to uppercase
    $domainNetbiosName = $domainNetbiosName.ToUpper()


    # Promote the first server to the first DC for the new forest/domain no reboot
    Install-ADDSForest -DomainName $domainName -DomainNetbiosName $domainNetbiosName -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd" -Force) -NoRebootOnCompletion


}
catch {
    Write-Host "An error occurred while configuring the domain: $($Error[0].Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Host "Domain configuration complete." -ForegroundColor Green
    # Say that the computer needs to be rebooted
    Write-Output "The computer needs to be rebooted." -ForegroundColor Yellow
    # Reboot the computer but ask for confirmation
    Restart-Computer -Confirm:$true
}
