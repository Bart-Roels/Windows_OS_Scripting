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
    Write-Host "Input:" $OU
    Write-Host "Creating OU:" -ForegroundColor Yellow
    Write-Host "Path: $path"
    Write-Host "DisplayName: $displayName"
    Write-Host "Description: $description"
    Write-Host "Name: $name"
    Write-Host "=================================="

    try {
        New-ADOrganizationalUnit -Name $name -Path $path -Description $description -DisplayName $displayName -ErrorAction Stop
    }
    catch {
        # Print the error message in red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

}

Write-Host "Users Created" -ForegroundColor Green
