# Prompt for the name of the printer to remove
$printerName = Read-Host "Enter the name of the printer to remove"

# Get the printer object
$printer = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
if ($printer -eq $null) {
    Write-Host "Printer '$printerName' not found" -ForegroundColor Red
    return
}

# Remove the printer
Write-Host "Removing printer '$printerName'..."
Remove-Printer -InputObject $printer

# Get the printer ports and check if they are associated with the printer being removed
$ports = Get-PrinterPort
foreach ($port in $ports) {
    if ($port.PrinterName -eq $printerName) {
        # Remove the port if it is not in use
        if ($port.Usage -eq "None") {
            Write-Host "Removing unused printer port '$($port.Name)'..."
            Remove-PrinterPort -InputObject $port
        }
    }
}
