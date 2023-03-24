# THIS SCRIPT CREATES A NEW SMB SHARE AND SETS THE ACL PERMISSIONS FOR THE SHARE FOLDER
# MS Server

try {
    $serverName = "WIN17-MS"
    # Define the share name and path
    $SystemShare = "C$"
    $drive = $SystemShare.replace("$", ":")
    $shareName = "Homes"
    $localPath = "$drive" + "\" + $shareName
    $path = "\\" + $serverName + "\" + $SystemShare + "\" + $shareName

    # Check if path exists
    if (Test-Path $path) {
        Write-Host "=================================="
        Write-Host "The path does exist on the server"
        write-host "=================================="

    }
    else {
        Write-Host "=================================="
        Write-Host "The path does not exist on the server"
        Write-Host "Creating the path on the server "
        write-host "=================================="
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }

    # Check if the share already exists
    if (Get-SmbShare -CimSession $serverName -Name $shareName -ErrorAction SilentlyContinue) {
        Write-Host "=================================="
        Write-Host "The share already exists on the server"
        write-host "=================================="
    }
    else {
        Write-Host "=================================="
        Write-Host "The share does not exist on the server"
        Write-Host "Creating the share on the server, shearing $localPath to $shareName on $serverName as $SystemShare "
        write-host "=================================="
        New-SmbShare -CimSession $serverName -Name $shareName -Path $localPath -FullAccess "Everyone"  | Out-Null
    }


    # Set the ACL permissions for the share folder
    $ACL = Get-Acl $path

    # Disable inheritance and remove all inherited permissions
    $ACL.SetAccessRuleProtection($true, $false)

    # Remove all users from the ACL except for Administrators
    $ACL.Access | Where-Object { $_.IdentityReference -ne "Administrators" } | ForEach-Object { $ACL.RemoveAccessRule($_) }

    # Set full control for the Administrators --> Container Inherit, Object Inherit
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $ACL.SetAccessRule($AccessRule)

    # Set read & execute for Authenticated Users on this folder only
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users", "ReadAndExecute", "None", "None", "Allow")
    
    $ACL.AddAccessRule($AccessRule)

    # Set the ACL permissions for the share folder
    Set-Acl $path $ACL

}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
}
