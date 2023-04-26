$PrinterName="HP Laserjet 4050"
$PrinterIP=”172.23.80.3”
$PrinterPort=$PrinterIP+"_TCPPort”

$PrinterLocation="KWE.A.2.105"
$PrinterShare="HPLJ4050-KWE.A.2.105"

# Get the driver file. Select the first, in case there are more
#$inf = Get-ChildItem -Path "C:\HP Universal Print Driver" -Recurse -Filter "*.inf" |
#    Where-Object Name -NotLike "Autorun.inf" |
#    Select-Object -First 1 |
#    Select-Object -ExpandProperty FullName

$inf = "C:\HP Universal Print Driver\pcl6-x64-7.0.1.24923\hpcu255u.inf"

# Check that the inf file is the one you're looking for
Write-Host "The inf file is '$inf'" -ForegroundColor Cyan

# Install the driver
PNPUtil.exe /add-driver $inf /install | Out-Null

# Retrieve driver info
$DismInfo = Dism.exe /online /Get-DriverInfo /driver:$inf

# Retrieve the printer driver name
$DriverName = ( $DismInfo | Select-String -Pattern "Description" | Select-Object -Last 1 ) -split " : " |
    Select-Object -Last 1

Write-Host "The driver name is '$DriverName'" -ForegroundColor Cyan

# Add driver to the list of available printers
Add-PrinterDriver -Name $DriverName -Verbose

# Add a network printer port
Add-PrinterPort -Name $PrinterPort -PrinterHostAddress $PrinterIP -ErrorAction SilentlyContinue -Verbose

#Add the printer and share it
Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PrinterPort -Location $PrinterLocation -Shared -ShareName $PrinterShare -Verbose
