# Add memebers to group

# Open the csv file
$memebers = Import-Csv -Path "C:\Users\Administrator\Downloads\GroupMembers.csv" -Delimiter ";" 

# Loop through the group members 
foreach ($member in $memebers) {

    # Get member name from csv file
    $memberName = $member.Member
    # Get identity from csv file
    $identity = $member.Identity


    # Print the OU settings
    Write-Host "=================================="
    Write-Host $member
    Write-Host "Adding member:"
    Write-Host "Member: $memberName"
    Write-Host "Identity: $identity"
    Write-Host "=================================="

    # Try to add the member to the group
    try {
        Add-ADGroupMember -Identity $identity -Members $memberName -ErrorAction Stop
        # Member added
        Write-Host "Member added - $memberName added to $identity" -ForegroundColor Green
    }
    catch {
        # Print the error message in red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
