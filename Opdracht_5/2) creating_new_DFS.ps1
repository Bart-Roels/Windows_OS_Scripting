#
# Creating a new DFS Namespaces
#

$UserDNSDomain=”intranet.mct.be”
$LocalPath="C:\XYZ"
$ShareName="XYZ"

$Target=”\\$env:COMPUTERNAME\$ShareName”
$Path=”\\$UserDNSDomain\$ShareName”

# Check if DFSRoot already exists
if (!(Test-Path $Target))
{
    # Check if local folder already exists
     if (!(Test-Path $LocalPath))
    {
	    # Create local folder
        New-Item -Path $LocalPath -ItemType Directory | Out-Null
    }
    # Share local folder
    New-SmbShare -Path $LocalPath -Name $ShareName -FullAccess Everyone | Out-Null
}

Write-Host "Creating DFSRoot $Target on $Path ..." -ForegroundColor Cyan
New-DfsnRoot -TargetPath "$Target" -Type DomainV2 -Path "$Path" | Out-Null

#
# Removing a DFSRoot
#

#Write-Host "Removing the DFSRoot $Target ..." -ForegroundColor Cyan
#Remove-DfsnRoot -Path "$Path" -Force | Out-Null
#Remove-SmbShare -Name $ShareName -Force | Out-Null
#Remove-Item -Path $LocalPath -Recurse -Force | Out-Null
