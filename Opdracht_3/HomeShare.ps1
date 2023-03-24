$session = New-PSSession -ComputerName WIN17-MS

Invoke-Command -Session $session -ScriptBlock {
    # Define the share name and path
    $shareName = "Homes"
    $sharePath = "C:\Shares\Homes"

    # Create the folder on the server
    New-Item -ItemType Directory -Path $sharePath -Force

    # Define the access rules
    $accessRules = @()
    $accessRules += New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "Allow")
    $accessRules += New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users", "ReadAndExecute", "Allow")

    # Set the NTFS permissions on the folder
    Set-Acl -Path $sharePath -AclObject (New-Object System.Security.AccessControl.DirectorySecurity -ArgumentList @($null, "AllowInherit", $accessRules, $false))

    # Create the share with Everyone full control
    New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Everyone"

    # Disable inheritance on the folder
    $acl = Get-Acl $sharePath
    $acl.SetAccessRuleProtection($true, $false)
    Set-Acl -Path $sharePath -AclObject $acl
}






