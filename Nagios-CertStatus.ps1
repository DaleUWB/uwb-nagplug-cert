<#
.SYNOPSIS
Nagios-CertStatus will return a status and a status code for a windows Nagios client to ingest.

.DESCRIPTION
Nagios-CertStatus will return a humna readable status and a status code for Nagios to ingest via 
the client installed on the windows machine. The executing machine will have at least signed certs 
executable. 

Critical (nagios 2) will return only certs in the critical timeframe

Warning (nagios 1) will return certs in the warning timeframe and Optional "-e" property to include (1) or exclude (0) expired certs in warning.

OK (nagios 0) will return valid certs

No Scripts or Error ( nagios 3 ) will signal somthing is wrong

.PARAMETER w
Number of days defined as the warning timeframe before the certificate expiration date. Default 30

.PARAMETER c
Number of days defined as the critical timeframe before the certificate expiration date. Default 7

.PARAMETER e
Boolean parameter to either include (1) expired certificates with a warning status, or exclude (0) expired certificates. Default 1

.EXAMPLE
.\Nagios-CertStatus.ps1 -w 30 -c 7 -e 0
This will return certificates expireing in 7 days as a critical if any, 
otherwise it will return certificates in warning. Expired certificates are ignored.

.EXAMPLE
.\Nagios-CertStatus.ps1 -w 120 -c 30 -e 1
This will return certificates expireing in 7 days as a critical if any, 
otherwise it will return certificates in warning. Expired certificates are ignored.

.OUTPUTS
This command will produce a formatted list of certificates

#>

param (
    [int]$w = 30,
    [int]$c = 7,
    [bool]$e = 1
)
$warnTS = New-TimeSpan -Days $w
$critTS = New-TimeSpan -Days $c
$today = Get-Date

$certlist = Get-ChildItem -path cert: -recurse 

# create arrays to store output
$certExpired = @()
$certCrit = @()
$certWarn = @()
$certGood = @()

# iterate and test certlist to see the status of each cert, recording cert to pertinent array
foreach($cert in $certlist) {
    
    if($cert.NotAfter -lt $today -and $cert.NotAfter) {
        $certExpired += $cert
        Continue
    } 
    elseif($cert.NotAfter -lt ($today+$critTS) -and $cert.NotAfter){
        $certCrit += $cert
        Continue
    }
    elseif($cert.NotAfter -lt ($today+$warnTS) -and $cert.NotAfter){
        $certWarn += $cert
        Continue
    }
    elseif($cert.NotAfter -gt ($today) ){
        $certGood += $cert
        Continue
    }
    else { 
        continue 
    }
}

# checking obj and assigning nagios code
# will write output and table go to nagios?
if ($certCrit.count -gt 0 ) {
    Write-Output "CRITICAL: `n" 
    $certCrit | Sort -Property NotAfter | Format-Table -Property NotAfter, Thumbprint, Subject
    exit 2 #Returns CRITICAL status
}
elseif ($certWarn.count -gt 0 ) {
    Write-Output " WARNING: `n" 
    $certWarn | Sort -Property NotAfter | Format-Table -Property NotAfter, Thumbprint, Subject
    exit 1 #Returns WARNING status
}
elseif ($certExpired.count -gt 0 -and $e -eq 1) {
    Write-Output " Expired: `n" 
    $certExpired | Sort -Property NotAfter | Format-Table -Property NotAfter, Thumbprint, Subject
    exit 1 #Returns WARNING status
}
elseif ($certGood.count -gt 0) {
    Write-Output "OK: `n"
    $certGood | Sort -Property NotAfter | Format-Table -Property NotAfter, Thumbprint, Subject
    exit 0 #Returns OK status
}
else {
    Write-Output "No Certificates or Script error" 
    #(uncomment for debuging) $certlist | Sort -Property NotAfter | Format-Table -Property NotAfter, Thumbprint, Subject
    exit 3 #unknown
}