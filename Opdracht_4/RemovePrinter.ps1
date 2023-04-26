#
# Removing a printer
#
$PrinterName="HP Laserjet 4050"

try
{
    Write-Host "Removing printer $PrinterName ..."
    Get-Printer -Name $PrinterName -ErrorAction Stop | Out-Null
    Remove-Printer -Name $PrinterName
}
catch
{
    Write-Host "Printer $PrinterName doesn't exist ..." -ForegroundColor Red
}

#
# Removing a printer port
#
$PrinterPort="172.23.80.3_2"
try
{
    Write-Host "Removing printer port $PrinterPort ..."
    Get-PrinterPort -Name $PrinterPort -ErrorAction Stop | Out-Null
    try
    {
        Remove-PrinterPort -Name $PrinterPort -ErrorAction Stop
    }
    catch
    {
    # Printer port is in use …
        Write-Host "Unable to remove printer port '$PrinterPort'" -ForegroundColor Red
    } 
}
catch
{
# Printer port is in use …
    Write-Host "Printer port $PrinterPort doesn't exist ..." -ForegroundColor Red
}

