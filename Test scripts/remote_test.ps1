# Connect to remote machine and run test scripts
$session = New-PSSession -ComputerName WIN17-MS

Invoke-Command -Session $session -ScriptBlock {
    # Hello World
    Write-Host "Hello World"
}