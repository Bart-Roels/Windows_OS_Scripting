# THIS SCRIPT CREATES A NEW SMB SHARE AND SETS THE ACL PERMISSIONS FOR THE SHARE FOLDER
# MS Server

try {
    $serverName = "win17-dc2"
    # Define the share name and path
    $SystemShare = "C$"
    $drive = $SystemShare.replace("$", ":")
    $rootShare = "Public"
    $localPath = "$drive" + "\" + $rootShare
    $path = "\\" + $serverName + "\" + $SystemShare + "\" + $rootShare

    # Check if path exists
    if (Get-Item -Path $path -ErrorAction SilentlyContinue)
    {
        Write-Host "=================================="
        Write-Host "The path does exist on the server"
        write-host "=================================="

    } 
    else 
    {
        Write-Host "=================================="
        Write-Host "The path does not exist on the server"
        Write-Host "Creating the path on the server "
        write-host "=================================="
        New-Item -Path $path -type directory -Force | Out-Null
    }

    # 
    # SHARE CODE
    #

    if (Get-SmbShare -CimSession $serverName -Name $rootShare -ErrorAction SilentlyContinue)
    {
        Write-Host "=================================="
        Write-Host "The share already exists on the server"
        write-host "=================================="
    } 
    else 
    {
        Write-Host "=================================="
        Write-Host "The share does not exist on the server"
        Write-Host "Creating the share on the server, shearing $localPath to $rootShare on $serverName as $SystemShare "
        write-host "=================================="

        # Create the share
        New-SmbShare -CimSession $serverName -Name $rootShare -Path $localPath -FullAccess Everyone | Out-Null

        
        # Set the ACL permissions for the share folder
        $acl=Get-Acl $path

        # Disable inheritance and remove all permissions
        $acl.SetAccessRuleProtection($True, $False)

        #  # Remove all users from the ACL except for Administrators
        $acl.Access | Where-Object { $_.IdentityReference -ne "Administrators" } | ForEach-Object { $ACL.RemoveAccessRule($_) }

        # Setting Full Control for Administrators
        $Identity="Administrators"
        $Permission="FullControl"
        $Inheritance="ContainerInherit, ObjectInherit"
        $Propagation="None"
        $AccessControlType="Allow"
        $rule= New-Object System.Security.AccessControl.FileSystemAccessRule($Identity,$Permission,$Inheritance,$Propagation,$AccessControlType)
        $acl.AddAccessRule($rule)

        # Setting Read & Execute for Authenticated Users on This Folder only
        $Identity="Authenticated Users"
        $Permission="ReadAndExecute"
        $Inheritance="None"
        $Propagation="NoPropagateInherit"
        $AccessControlType="Allow"
        $rule= New-Object System.Security.AccessControl.FileSystemAccessRule($Identity,$Permission,$Inheritance,$Propagation,$AccessControlType)
        $acl.AddAccessRule($rule)

        Set-Acl $path $acl
    }


}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
}
