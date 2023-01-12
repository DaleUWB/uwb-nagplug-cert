<#
.SYNOPSIS
Nagios-CertStatus will return a status and a status code for a windows Nagios client to ingest.

.DESCRIPTION
Nagios-CertStatus will return a humna readable status and a status code for Nagios to ingest via 
the client installed on the windows machine. The executing machine will have at least signed certs 
executable. 

.EXAMPLE
Nagios-CertStatus -cert server.uwb.edu

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

# test certlist to see the status of each cert, recording subjectName and expiration date to pertinent array
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

# take output arrays and test to see if they have entries, output pertinent array and nagios code
if ($certCrit.count -gt 0 ) {
    Write-Output "CRITICAL($critTS): `n" 
    $certCrit | Sort -Property NotAfter | Format-Table -Property NotAfter, Thumbprint, Subject
    exit 2 #Returns CRITICAL STATUS
}
elseif ($certWarn.count -gt 0 ) {
    Write-Output " WARNING($warnTS): `n" 
    $certWarn | Sort -Property NotAfter | Format-Table -Property NotAfter, Thumbprint, Subject
    exit 1 #Returns WARNING STATUS
}
elseif ($certExpired.count -gt 0 -and $e -eq 1) {
    Write-Output " Expired: `n" 
    $certExpired | Sort -Property NotAfter | Format-Table -Property NotAfter, Thumbprint, Subject
    exit 1 #Returns WARNING status for expired
}
elseif ($certGood.count -gt 0) {
    Write-Output "OK: `n"
    $certGood | Sort -Property NotAfter | Format-Table -Property NotAfter, Thumbprint, Subject
    exit 0 #Returns OK STATUS
}
else {
    Write-Output "No Certificates or Script error" 
    $certlist | Sort -Property NotAfter | Format-Table -Property NotAfter, Thumbprint, Subject
    exit 3 #unknown
}