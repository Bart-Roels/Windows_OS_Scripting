# THIS SCRIPT CREATES A NEW SMB SHARE AND SETS THE ACL PERMISSIONS FOR THE SHARE FOLDER
# MS Server

$serverName = "WIN17-MS"
# Define the share name and path
$SystemShare = "C$"
$drive = $SystemShare.replace("$",":")
$shareName = "Homes"
$localPath = "$drive"+ "\" + $shareName
$path = "\\" + $serverName + "\" +$SystemShare + "\" + $shareName

# Check if path exists
if(Test-Path $path) {
    Write-Host "The share already exists on the server"
    return
}
else {
    Write-Host "The share does not exist on the server"
    Write-Host "Creating the share on the server"
    New-Item -Path $path Directory -Force | Out-Null
}

# Check if the share already exists
if(Get-SmbShare -CimSession $serverName -Name $shareName -ErrorAction SilentlyContinue) {
    Write-Host "The share already exists on the server"
    return
}
else {
    Write-Host "The share does not exist on the server"
    Write-Host "Creating the share on the server"
    New-SmbShare -CimSession $serverName -Name $shareName -Path $path -FullAccess "Everyone"  | Out-Null
}

# Set the ACL permissions for the share folder
$ACL = Get-Acl $path
# Disable inheritance and remove all inherited permissions
$ACL.SetAccessRuleProtection($true,$false)
# Settings full control for the Administrators --> Container Inherit, Object Inherit
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$ACL.SetAccessRule($AccessRule)

# set read & execute for Authenticated Users on this folder only -> No Inheritance, no propagation
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users","ReadAndExecute","None","None","Allow")
$ACL.SetAccessRule($AccessRule)
