Add-Type -AssemblyName Microsoft.VisualBasic

# Add printer script

# Check if the printer service is already installed
if (!(Get-WindowsFeature -Name Print-Server).Installed) {
    write-host "Printer service is not installed, installing now..." -ForegroundColor Yellow
    # Install the printer service
    Install-WindowsFeature -Name Print-Server -IncludeAllSubFeature -IncludeManagementTools 
}
else {
    write-host "Printer service is already installed" -ForegroundColor Green
}

# Change spooler settings
# Ask for a new spooler location
$spoolerLocation = Read-Host "Enter a new spooler location"
# Try to change the spooler location
try {
    Set-PrinterConfiguration -SpoolDirectory $spoolerLocation -ErrorAction Stop
    # Print the new spooler location
    Write-Host "Spooler location changed to: $spoolerLocation" -ForegroundColor Green
}
catch {
    # Print the error message in red
    Write-Host "Error changing spooler location default location will be used" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Check if the printer driver is installed
Get-PrinterDriver
Write-Host ""
$ans = Read-Host -Prompt "Do you see your printer driver? (Y/N)"
while ($True) {
    if ($ans.ToLower() -eq "y") {
        Write-Host "The printer driver is installed." -ForegroundColor Green
        Write-Host "Continue to installing the printer." -ForegroundColor Green
        installPrinter
    }
    elseif ($ans.ToLower() -eq "n") {
        # Please install a suitable printer driver
        Write-Host "Please install a suitable printer driver." -ForegroundColor Yellow
        break
    }
    else {
        Get-PrinterDriver
        Write-Host ""
        Write-Host "Error: Please enter Y or N." -ForegroundColor Red
        $ans = Read-Host -Prompt "Do you see your printer driver? (Y/N)"
    }
}

function installPrinter {
    # Install and share a network printer
    $printerName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the printer name", "printername")


    while ($printerName -eq "") {
        Write-Host "Error: The printer name cannot be empty." -ForegroundColor Red
        $printerName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the printer name", "printername")
        #check if the printername is already in use
        while (Get-Printer -Name $printerName) {
            Write-Host "Warning: The printer name is already in use." -ForegroundColor Yellow
            $printerName = Read-Host -Prompt "Do you wish to overwrite it? (can cause problems)"
        }
    }

    # Ask for the ip address that you want to use
    $printerIPAddress = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the printer IP address", "printeripaddress")

    # Check if the ip address is empty and is valid
    while ($printerIPAddress -eq "") {
        # Check if the ip address is valid
        while ($printerIPAddress -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$") {
            Write-Host "Error: The printer IP address is not valid." -ForegroundColor Red
            $printerIPAddress = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the printer IP address", "printer ipaddress")
        }
        # Empty ip address
        Write-Host "Error: The printer IP address cannot be empty." -ForegroundColor Red
        $printerIPAddress = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the printer IP address", "printer ipaddress")
    }

    # Ask for the printer port that you want to use
    $printerPort = Read-Host -Prompt "Enter the printer port:"
    while ($printerPort -eq "") {
        Write-Host "Error: The printer port cannot be empty." -ForegroundColor Red
        $printerPort = Read-Host -Prompt "Enter the printer port [no ip address!]:"
    }

    # Try to install the printer
    try {
        write-host "Installing the printer named $printerName." -ForegroundColor Green
        Write-Host "Installing the printer driver named $printerDriver." -ForegroundColor Green
        Write-Host "Installing the printer port named $printerPort." -ForegroundColor Green

        Write-Host "Installing the printer." -ForegroundColor Green
        Add-PrinterPort -Name $printerPort -PrinterHostAddress $printerIPAddress
        Write-Host "The printer port has been added." -ForegroundColor Green

        # Show all printer drivers
        Get-PrinterDriver -Name *
        # Ask for the printer driver
        $printerDriver = Read-Host -Prompt "Enter the printer driver:"
        # Check if the printer driver is empty
        while ($printerDriver -eq "") {
            Write-Host "Error: The printer driver cannot be empty." -ForegroundColor Red
            $printerDriver = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the printer driver", "printer driver")

        }
        # Get specified printer driver
        $driver = Get-PrinterDriver -Name $printerDriver -ErrorAction Stop
        # Get InfPath 
        $driverPath = $driver.InfPath


        Add-PrinterDriver -Name $printerDriver -InfPath $driverPath
        Write-Host "The printer driver has been installed." -ForegroundColor Green

        # Add the printer
        Add-Printer -Name $printerName -DriverName $printerDriver -PortName $printerPort
        Write-Host "> The printer has been added." -ForegroundColor Green
        
        # Share the printer
        $ans = Read-Host -Prompt "Do you want to share the printer? (Y/N)"
        while ($True) {
            if ($ans -eq "y") {
                $shareName = Read-Host -Prompt "Enter the share name:"
                while ($shareName -eq "") {
                    Write-Host "> Error: The share name cannot be empty." -ForegroundColor Red
                    $shareName = Read-Host -Prompt "Enter the share name:"
                }
                $shareLocation = Read-Host -Prompt "Enter the location of the printer:"
                while ($shareLocation -eq "") {
                    Write-Host "> Error: The location of the printer cannot be empty." -ForegroundColor Red
                    $shareLocation = Read-Host -Prompt "Enter the location of the printer:"
                }
                Set-Printer -Name $printerName -Location $shareLocation -Shared $True -ShareName $shareName
                Write-Host "> The printer is shared as $shareName." -ForegroundColor Green
                Write-Host "> The printer is located at $printerLocation." -ForegroundColor Green
                Write-Host "> The printer is available at \\$env:COMPUTERNAME\$shareName." -ForegroundColor Green
                break
            }
            elseif ($ans -eq "n") {
                Write-Host "> The printer is not shared." -ForegroundColor Yellow
                break
            }
            else {
                Write-Host "> Error: Please enter Y or N." -ForegroundColor Red
                $ans = Read-Host -Prompt "Do you want to share the printer? (Y/N)"
            }
        }
        
    }
    catch {
        #show error
        Write-Error "> Error: $($_.Exception.Message)"
        Write-Host "> Error: The printer could not be installed." -ForegroundColor Red
        $ans = Read-Host -Prompt "Try again? (Y/N)"
        while ($True) {
            if ($ans.ToLower() -eq "y") {
                checkPrinterDriver
                break
            }
            elseif ($ans.ToLower() -eq "n") {
                Write-Host "> No printer is installed" -ForegroundColor Red
                break
            }
            else {
                Write-Host "> Error: Please enter Y or N." -ForegroundColor Red
                $ans = Read-Host -Prompt "Try again? (Y/N)"
            }
        }
    }
}




