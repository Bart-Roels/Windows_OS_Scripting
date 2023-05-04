#
# Install Printer Management
#

$ComputerName=$env:COMPUTERNAME

$WindowsFeature="Print-Server"
if (Get-WindowsFeature $WindowsFeature -ComputerName $ComputerName | Where-Object { $_.installed -eq $false })
{
    Write-Output "Installing $WindowsFeature ..."
    Install-WindowsFeature $WindowsFeature -ComputerName $ComputerName -IncludeManagementTools
}
else
{
    Write-Output "$WindowsFeature already installed ..."
}


#
# DefaultSpooldirectory is c:\windows\system32\spool\PRINTERS
#

$SpoolFolder = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers").DefaultSpoolDirectory
$NewSpoolFolder="C:\Output"
$Path=$NewSpoolFolder

if (Get-Item -Path $Path -ErrorAction SilentlyContinue)
{
 	write-host $Path "already exists ..."   
}
else
{
    write-host "Creating $Path ..." 
    New-Item -Path $Path -type directory -Force | Out-Null
}

Stop-Service -Name "Spooler" -Force

Move-Item $SpoolFolder\*.* $NewSpoolFolder -force
Set-ItemProperty -Name DefaultSpoolDirectory -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers" -Value $NewSpoolFolder

Start-Service -Name "Spooler"

