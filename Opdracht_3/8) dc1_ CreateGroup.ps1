# Create groups in OU

# Open the csv and add the group names
$groups = Import-Csv -Path "C:\Users\Administrator\Downloads\Groups.csv" -Delimiter ";" 

# Loop through the OU names
foreach ($group in $groups) {

    # Get Path from csv file
    $path = $group.Path
    # Get Name from csv file
    $name = $group.Name
    # Get DisplayName from csv file
    $displayName = $group.DisplayName
    # Get Description from csv file
    $description = $group.Description
    # Get GroupScope from csv file
    $groupScope = $group.GroupScope
    # Get GroupCategory from csv file
    $groupCategory = $group.GroupCategory


    # Try to create the new GROUP in Active Directory
    try {
        New-ADGroup -Name $name -Path $path -Description $description -DisplayName $displayName -GroupScope $groupScope -GroupCategory $groupCategory -ErrorAction Stop
    }
    catch {
        # Print the error message in red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

}
