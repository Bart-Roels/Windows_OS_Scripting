#
# Creating a DFS Link Folder
#
$UserDNSDomain=”intranet.mct.be”
$ShareName="XYZ"
$DFSRoot=”\\$env:COMPUTERNAME\$ShareName”

$Folder="$DFSRoot\General"
$FolderTarget="\\MS\ABCco"

try {
    Get-DfsnFolderTarget -Path $Folder -ErrorAction Stop
} catch {
    Write-Host "$Folder not found. Clear to proceed" -ForegroundColor Green
}

$NewDFSFolder = @{
    Path = $Folder
    State = 'Online'
    TargetPath = $FolderTarget
    TargetState = 'Online'
    ReferralPriorityClass = 'globalhigh'
}

New-DfsnFolder @NewDFSFolder | Out-Null

# Check that folder now exists:
Get-DfsnFolderTarget -Path $Folder -TargetPath $FolderTarget

#
# Remove DFS Folder Target or Remove DFS Link Folder
#
#Remove-DfsnFolderTarget -Path $Folder -TargetPath $FolderTarget -Force
# or
#Remove-DfsnFolder -Path $Folder -Force
