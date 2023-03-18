# THIS SCRIPT CREATES A NEW SMB SHARE AND SETS THE ACL PERMISSIONS FOR THE SHARE FOLDER
# DC 2 

# Set variables
$shareName = "UserProfiles"
$sharePath = "C:\UserProfiles"
$shareDescription = "Shared folder for user profiles"

# Create the new SMB share
New-SmbShare -Name $shareName -Path $sharePath -Description $shareDescription -FullAccess Everyone

# Set the ACL permissions for the share folder
$ACL = Get-Acl $sharePath
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","Allow")
$ACL.SetAccessRule($AccessRule)
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users","ReadAndExecute","Allow")
$ACL.SetAccessRule($AccessRule)
Set-Acl $sharePath $ACL

# Set the share access rule protection to "NoPropagateInherit"
Set-SmbShare -Name $shareName -FolderEnumerationMode AccessBased -FolderEnumerationModeFlags NoAccessBasedEnumeration


