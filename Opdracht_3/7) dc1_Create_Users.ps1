#
#
# PAS DE LIJN OP FUCKING LIJN 27 AAN!!!!!!!!!!!!!!
#
# 

# Open the csv file and add the user names
$userList = Import-Csv -Path "C:\Users\Administrator\Downloads\Board.csv" -Delimiter ";"

# Loop through the user names
foreach ($user in $userList) {
    # Get Name from csv file
    $surname = $user.Name
    # Get Surname from csv file
    $name = $user.Surname
    # Get DisplayName from csv file
    $displayName = $user.DisplayName
    # Get SamAccountName from csv file
    $samAccountName = $user.SamAccountName
    # Get UserPrincipalName from csv file
    $userPrincipalName = $user.UserPrincipalName
    # Get Password from csv file
    $password  = $user.AccountPassword
    # Get Path from csv file
    $path = $user.Path
    # Get home directory from csv file
    $homeDirectory = "\\MS\Homes\$samAccountName"
    # Drive letter
    $driveletter = $user.Driveletter
    # Get upn suffix from server
    $upnSuffix = Get-ADForest | Select-Object -ExpandProperty UPNSuffixes
    # User principal name
    $userPrincipalName = "$samAccountName@$upnSuffix"
    # Lastname
    $lastname = $surname
    # Description
    $desc = $user.Description

    # Print the user settings
    Write-Host "=================================="
    Write-Host $user
    write-host "Creating user:" -ForegroundColor Yellow
    Write-Host "FirstName (name): $name"
    Write-Host "Lastname (lastname): "$lastname
    Write-Host "DisplayName: $displayName"
    Write-Host "SamAccountName: $samAccountName"
    Write-Host "UserPrincipalName: $userPrincipalName"
    Write-Host "Password: $password"
    Write-Host "Path: $path"
    Write-Host "Description: $desc"
    Write-Host "DriveLetter: $driveletter"
    Write-Host "HomeDirectory: $homeDirectory"
    Write-Host "=================================="

   
    try
    {
        Get-ADUser -identity $samAccountName | Out-Null
        Write-Output "$Name already exists in $Path!" -ForegroundColor Red
    }
    catch
    {
    	    
        
        Write-Output "Making $User.Name in $Path ..." 

	    
        New-ADUser -Name $name -GivenName $givenName -Description $desc -Surname $lastname -DisplayName $displayName -SamAccountName $samAccountName -UserPrincipalName $userPrincipalName -Path $path -HomeDirectory $homeDirectory -HomeDrive  $driveletter -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true -ErrorAction Stop
        
        New-Item -Path $homeDirectory -type directory -Force
    
        $acl=Get-Acl $homeDirectory

        # Enable inheritance and copy permissions
        $acl.SetAccessRuleProtection($False, $True)
 
        # Setting Modify for the User account
        $Identity=$userPrincipalName
        $Permission="Modify"
        $Inheritance="ContainerInherit, ObjectInherit"
        $Propagation="None"
        $AccessControlType="Allow"
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity,$Permission,$Inheritance,$Propagation,$AccessControlType)
	    $acl.AddAccessRule($rule)
 
	    Set-Acl $HomeDirectory $acl
	}

    Write-Host "User created" -ForegroundColor Green
}




