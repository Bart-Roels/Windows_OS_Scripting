# Create OU in Active Directory 

# Open the csv file and add the OU names
$OUs = Import-Csv -Path "C:\Users\Administrator\Downloads\OU.csv" -Delimiter ";" | Select-Object -Skip 1

# Loop through the OU names
foreach ($OU in $OUs) {
    Write-Host $OU
    # Get Path from csv file
    $path = $OU.Path
    # Get DisplayName from csv file
    $displayName = $OU.DisplayName
    # Get Description from csv file
    $description = $OU.Description
    # Get name from csv file
    $name = $OU.Name

    # Print the OU settings
    Write-Host "=================================="
    Write-Host "Creating OU:"
    Write-Host "Path: $path"
    Write-Host "DisplayName: $displayName"
    Write-Host "Description: $description"
    Write-Host "Name: $name"
    Write-Host "=================================="

    # Try to create the new OU in Active Directory
    try {
        New-ADOrganizationalUnit -Name $name -Path $path -Description $description -DisplayName $displayName -ErrorAction Stop
    }
    catch {
        # Print the error message in red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
