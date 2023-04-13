# Set variables for server names and folder targets
$nps_server = "NPS01"
$ca_server = "CA01"
$radius_clients_csv = "C:\temp\RadiusClients.csv"

# Check if the Certificate Authority and NPS services are installed
$ca_service = Get-Service -ComputerName $ca_server -Name "CertSvc" -ErrorAction SilentlyContinue
if (!$ca_service) {
    Write-Error "The Certificate Authority service is not installed on $ca_server."
    return
}

$nps_service = Get-Service -ComputerName $nps_server -Name "IAS" -ErrorAction SilentlyContinue
if (!$nps_service) {
    Write-Error "The Network Policy Server service is not installed on $nps_server."
    return
}

# Register the NPS server in Active Directory
$ad_path = "OU=Servers,DC=contoso,DC=com"
$ad_nps_server = Get-ADComputer -Filter { Name -eq $nps_server } -SearchBase $ad_path -ErrorAction SilentlyContinue
if (!$ad_nps_server) {
    Write-Error "The NPS server $nps_server was not found in Active Directory."
    return
}

$ad_nps_service = Get-ADObject -Filter { ObjectClass -eq "serviceConnectionPoint" -and Name -eq "Microsoft Network Policy Server" } -SearchBase $ad_path -ErrorAction SilentlyContinue
if (!$ad_nps_service) {
    $nps_spn = "HOST/$nps_server"
    New-ADServiceAccount -Name "NPS" -DNSHostName $nps_server -ServicePrincipalNames $nps_spn -Path $ad_path
    $ad_nps_service = Get-ADObject -Filter { ObjectClass -eq "serviceConnectionPoint" -and Name -eq "Microsoft Network Policy Server" } -SearchBase $ad_path
}

Set-ADObject -Identity $ad_nps_service.DistinguishedName -Add @{serviceBindingInformation = "$nps_server" }

# Configure the Certificate Authority for the domain and create a default self-signed certificate with a validity of 10 years
$cert_template = "Computer"
$cert_subject = "CN=$ca_server-CA,DC=contoso,DC=com"
$cert_start_date = (Get-Date).AddDays(-1)
$cert_end_date = (Get-Date).AddYears(10)
$cert_password = ConvertTo-SecureString -String "P@ssw0rd" -AsPlainText -Force
$cert_template_oid = (Get-CertificateTemplate -Name $cert_template).Oid.Value

$ca = Get-CertificationAuthority -ComputerName $ca_server
if (!$ca) {
    Write-Error "Failed to retrieve Certification Authority information from $ca_server."
    return
}

$cert = New-SelfSignedCertificate -DnsName $cert_subject -CertStoreLocation Cert:\LocalMachine\My -NotBefore $cert_start_date -NotAfter $cert_end_date -SubjectName "DC=contoso,DC=com" -FriendlyName "Contoso CA" -Type Custom -Template $cert_template_oid -KeyUsage DigitalSignature, KeyEncipherment -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 -ProviderName "Microsoft Enhanced RSA and AES Cryptographic Provider" -KeyPassword $cert_password
if (!$cert) {
    Write-Error "Failed to create a self-signed certificate for $ca_server."
    return
}

$ca.SetCertificate($cert)


# Create five Radius clients from a CSV file in NPS
$radius_clients = Import-Csv -Path $radius_clients_csv
foreach ($client in $radius_clients) {
    $client_name = $client.Name
    $client_address = $client.Address
    $client_secret = $client.Secret
    $client_vendor = $client.Vendor
    $client_auth = $client.Authentication
    $client_acct = $client.Accounting

    # Create the Radius client
    Add-RemoteRadiusClient -Name $client_name -Address $client_address -AuthenticationPort 1812 -AccountingPort 1813 -SharedSecret $client_secret -VendorName $client_vendor -UseWindowsAuthentication $client_auth -UseAccountingOnOff $client_acct

}



# Export and import the complete NPS configuration
Export-NpsConfiguration -Path "C:\temp\npsconfig.xml"
Import-NpsConfiguration -Path "C:\temp\npsconfig.xml"


# Check if the firewall rules are configured to allow incoming Radius traffic (UDP 1812 and UDP 1813)

$firewall_rule = Get-NetFirewallRule -DisplayName "Routing and Remote Access (GRE-In)"
if (!$firewall_rule) {
    Write-Error "The firewall rule for incoming Radius traffic (UDP 1812 and UDP 1813) is not configured."
    return
}
else {
    Write-Output "The firewall rule for incoming Radius traffic (UDP 1812 and UDP 1813) is configured."
}

