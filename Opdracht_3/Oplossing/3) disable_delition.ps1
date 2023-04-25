#
# Disabling accidental deletion on the OUs
#

$OUs = Import-Csv -Path "C:\Users\Administrator\Downloads\OU.csv" -Delimiter ";" 
 
Foreach ($OU in $OUs)
{ 
	$Name = $OU.Name
	$DisplayName = $OU.DisplayName
	$Description = $OU.Description
	$Path = "OU=" + $Name + "," + $OU.Path

	set-ADOrganizationalUnit -Identity $Path -ProtectedFromAccidentalDeletion:$false
}
