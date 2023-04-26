#
# Printer available from 8:00am till 19:00pm
#
$PrinterName="HP Laserjet 4050"

$Start=”420” # 8:00am = 60*7
$Until="1080" # 7:00pm = 60*18

Set-Printer -Name $PrinterName -StartTime “$Start” -UntilTime “$Until” -Verbose

#
# Always available
#
$PrinterName="HP Laserjet 4050"

$Start=”0”
$Until="0"

Set-Printer -Name $PrinterName -StartTime “$Start” -UntilTime “$Until” -Verbose
