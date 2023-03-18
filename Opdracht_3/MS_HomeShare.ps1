# Define the share name and path
$shareName = "Homes"
# Share path on member server ms17
$sharePath = "\\ms17\Homes"

# Create remote session to member server ms17
$session = New-PSSession -ComputerName ms17

# Import the SMB module on the member server
Import-Module -Name SmbShare -PSSession $session

# Create the folder on the member server
New-Item -ItemType Directory -Path $sharePath -Force -PSSession $session

# Create the home share
New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Domain Users" -PSSession $session

# Every one full control on the share
Set-SmbShareAccess -Name $shareName -AccessRight "FullControl" -AccountName "Everyone" -PSSession $session

# Get the ACL for the shared folder
$acl = Get-Acl $sharePath -PSSession $session

# Disable inheritance on the folder 
$acl.SetAccessRuleProtection($true, $false)

# Remove any existing access rules
$acl.Access | % { $acl.RemoveAccessRule($_) }

# Ntfs permissions on the folder on the member server
# Administrator full control
$rule1 = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrator","FullControl","Allow")
# authenticated users read and execute
$rule2 = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users","ReadAndExecute","Allow")

# Add the rules to the ACL
$acl.AddAccessRule($rule1)
$acl.AddAccessRule($rule2)

# Set the ACL for the shared folder
Set-Acl -Path $sharePath -AclObject $acl -PSSession $session














