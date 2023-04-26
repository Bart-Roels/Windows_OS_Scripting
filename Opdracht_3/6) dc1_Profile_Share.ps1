# THIS SCRIPT CREATES A NEW SMB SHARE AND SETS THE ACL PERMISSIONS FOR THE SHARE FOLDER
# MS Server

try {
    $serverName = "MS"
    # Define the share name and path
    $SystemShare = "C$"
    $drive = $SystemShare.replace("$", ":")
    $rootShare = "Profiles"
    $localPath = "$drive" + "\" + $rootShare
    $path = "\\" + $serverName + "\" + $SystemShare + "\" + $rootShare

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
        New-Item -Path $path -type directory -Force | Out-Null
    }

    # Check if the share already exists
    if (Get-SmbShare -CimSession $serverName -Name $rootShare -ErrorAction SilentlyContinue) {
        Write-Host "=================================="
        Write-Host "The share already exists on the server"
        write-host "=================================="
    }
    else {
        Write-Host "=================================="
        Write-Host "The share does not exist on the server"
        Write-Host "Creating the share on the server, shearing $localPath to $rootShare on $serverName as $SystemShare "
        write-host "=================================="
        New-SmbShare -CimSession $serverName -Name $rootShare -Path $localPath -FullAccess Everyone | Out-Null    
    

        $acl=Get-Acl $path

        # Disable inheritance and remove all permissions
        $acl.SetAccessRuleProtection($True, $False)

        # Setting Full Control for Administrators
        $Identity="Administrators"
        $Permission="FullControl"
        $Inheritance="ContainerInherit, ObjectInherit"
        $Propagation="None"
        $AccessControlType="Allow"


        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity,$Permission,$Inheritance,$Propagation,$AccessControlType)
        $acl.SetAccessRule($AccessRule)

        # Setting Modify for Authenticated Users
        $Identity="Authenticated Users"
        $Permission="Modify"
        $Inheritance="ContainerInherit, ObjectInherit"
        $Propagation="None"
        $AccessControlType="Allow"

        $AccessRule=New-Object System.Security.AccessControl.FileSystemAccessRule($Identity,$Permission,$Inheritance,$Propagation,$AccessControlType)
        $acl.SetAccessRule($AccessRule)

        Set-Acl $path $acl

    }
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
}
