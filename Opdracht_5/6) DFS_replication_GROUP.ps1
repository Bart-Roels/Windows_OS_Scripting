#
# Creating a DFS Replication group with two members and force a sync 
#
$DFSRGroup="demo"
$DFSRFolder="little_demo"

$DFSRMembers=@("MS","DC2")
$DFSRContentPaths=@("c:\demofolder","c:\demofolder")

try {
    New-DfsReplicationGroup -GroupName $DFSRGroup -ErrorAction Stop | Out-Null                                                                                      
    Write-Host "Creating the DFSR Group $DFSRGroup ..."
} catch {
    Write-Host "DFSR Group $DFSRGroup already exists ..."
}

try {
    New-DfsReplicatedFolder -FolderName $DFSRFolder -GroupName $DFSRGroup -ErrorAction Stop | Out-Null
    Write-Host "Creating the DFSR Folder $DFSRFolder in the DFSR Group $DFSRGroup ..."
} catch {
    Write-Host "DFSR Folder $DFSRFolder already exists in DFSR Group $DFSRGroup ..."
}

for ($i=0; $i -lt $DFSRMembers.Length; ++$i)
{
    $DFSRMember=$DFSRMembers[$i]
    try {
        Add-DfsrMember -ComputerName $DFSRMember -GroupName $DFSRGroup -ErrorAction Stop | Out-Null
        Write-Host "Adding the DFSR Member $DFSRMember in the DFSR Group $DFSRGroup …"
    } catch {
        Write-Host "The DFSR Member $DFSRMember is already member of the DFSR Group $DFSRGroup …"
    }
}

$Source=$DFSRMembers[0]
$Destination=$DFSRMembers[1]

try {
    Add-DfsrConnection -SourceComputerName $Source -DestinationComputerName $Destination -GroupName $DFSRGroup -ErrorAction Stop | Out-Null
    Write-Host "Adding the DFSR Connection between $Source and $Destination ..."
} catch {
    Write-Host "The DFSR Connection between $Source and $Destination already exists ..."
}

for ($i=0; $i -lt $DFSRMembers.Length; ++$i)
{
    try {
        $DFSRMember=$DFSRMembers[$i]
        $DFSRContentPath=$DFSRContentPaths[$i]
        Set-DfsrMembership -ComputerName $DFSRMember -FolderName $DFSRFolder -GroupName $DFSRGroup -ContentPath $DFSRContentPath -Force -ErrorAction Stop | Out-Null
        Write-Host "Adding the DFSR Member $DFSRMember with the local path $DFSRContentPath to the DFSR Folder $DFSRFolder in the DFSR Group $DFSRGroup …"
    } catch {
        Write-Host "The DFSR Member $DFSRMember with the local path $DFSRContentPath already added to the DFSR Folder $DFSRFolder in the DFSR Group $DFSRGroup …"
    }
}

Sync-DfsReplicationGroup -GroupName $DFSRGroup -SourceComputerName $Source -DestinationComputerName $Destination -DurationInMinutes 15 | Out-Null
