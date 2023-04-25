# Create OU in Active Directory 

# Open the csv file and add the OU names
$OUs = Import-Csv -Path "C:\Users\Administrator\Downloads\OU.csv" -Delimiter ";" 

# Loop through the OU names
foreach ($OU in $OUs) {

    # Get Path from csv file
    $path = $OU.Path
    # Get DisplayName from csv file
    $displayName = $OU.DisplayName
    # Get Description from csv file
    $description = $OU.Description
    # Get name from csv file
    $name = $OU.Name
    # Create the Identity
	$identity="OU="+$name+","+$path


    # Print the OU settings
    Write-Host "=================================="
    Write-Host $OU
    Write-Host "Creating OU:"
    Write-Host "Path: $path"
    Write-Host "DisplayName: $displayName"
    Write-Host "Description: $description"
    Write-Host "Name: $name"
    Write-Host "=================================="

    try
	{
		Get-ADOrganizationalUnit -Identity $Identity | Out-Null
		Write-Output "OU $Name already exists in $Path !" -ForegroundColor Red
	}
	catch
	{
		Write-Output "Making OU $Name in $Path ..." 
		New-ADOrganizationalUnit -Name $name -DisplayName $displayName  -Description $description -Path $path
	}

}
