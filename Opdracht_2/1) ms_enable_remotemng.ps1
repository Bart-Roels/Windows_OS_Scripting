$session = New-PSSession -ComputerName WIN17-MS

# Invoke-Command -Session $session -ScriptBlock {
Invoke-Command -Session $session -ScriptBlock {
    #
    # Enabling Remote Management on the core server
    #

    # QWERTY
    #Set-WinUserLanguageList -LanguageList en-US -Force
    
    # AZERTY
    Set-WinUserLanguageList -LanguageList nl-BE -Force

    Enable-PSRemoting -Force
    Enable-NetFirewallRule -DisplayName "*Network Access*"
    Enable-NetFirewallRule -DisplayGroup "*Remote Event Log*"
    Enable-NetFirewallRule -DisplayGroup "*Remote File Server Resource Manager Management*"
    Enable-NetFirewallRule -DisplayGroup "*Netlogon Service*"

}

# Close the session
Remove-PSSession $session

# Print server is configured
Write-Host "Server is configured" -ForegroundColor Green






