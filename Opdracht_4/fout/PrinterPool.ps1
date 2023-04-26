# Import necessary modules
Import-Module PrintManagement

# Define printer pool name
$poolName = "MyPrinterPool"

# Define the printer ports to be added to the pool
$printerPorts = "172.23.80.3", "172.23.82.3"

# Create a new printer pool
New-PrinterPool -Name $poolName

# Add the specified printer ports to the pool
foreach ($port in $printerPorts) {
    Add-PrinterPort -PrinterPoolName $poolName -Name $port
}

# Share the printer pool
Set-PrinterPool -Name $poolName -Shared $true

# Display the details of the printer pool
Get-PrinterPool -Name $poolName

# # To undo the changes made, simply remove the printer ports from the pool and delete the printer pool
# foreach ($port in $printerPorts) {
#     Remove-PrinterPort -PrinterPoolName $poolName -Name $port
# }

# Remove-PrinterPool -Name $poolName
