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

$certlist = get-childitem -path cert: -recurse #-Expiringindays $w

# create arrays to store output
$certExpired = @()
$certCrit = @()
$certWarn = @()
$certGood = @()

# test certlist to see the status of each cert, recording subjectName and expiration date to pertinent array
foreach($cert in $certlist) {
    $cert.NotAfter ? ($dt = $cert.NotAfter.ToString()) : ( $dt = 'Location' )
    $cert.SubjectName.Name ? ($nm = $cert.SubjectName.Name.ToString()) : ( $nm = $cert )
    
    if($cert.NotAfter -lt $today) {
        $certExpired += " $dt : $nm"
        Continue
    } 
    elseif($cert.NotAfter -lt ($today+$critTS) ){
        $certCrit += " $dt : $nm"
        Continue
    }
    elseif($cert.NotAfter -lt ($today+$warnTS) ){
        $certWarn += " $dt : $nm"
        Continue
    }
    elseif($cert.NotAfter -gt ($today) ){
        $certGood += " $dt : $nm"
        Continue
    }
    else { 
        continue 
    }
}

# take output arrays and test to see if they have entries, output pertinent array and nagios code
if ($certCrit.count -gt 0 ) {
    Write-Output "CRITICAL($critTS): $certCrit"
    exit 2 #Returns CRITICAL STATUS
}
elseif ($certWarn.count -gt 0 ) {
    Write-Output " WARNING($warnTS): $certWarn"  
    exit 1 #Returns WARNING STATUS
}
elseif ($certExpired.count -gt 0 -and $e -eq 1) {
    Write-Output " Expired: $certExpired"  
    if($includeExpired) { exit 1 } else { exit 0 } #tried a ternary but errored on "exit", returning "ok" to nagios for empty
}
elseif ($certGood.count -gt 0) {
    Write-Output "OK: $certGood"
    exit 0 #Returns OK STATUS
}
else {
    Write-Output "No Certificates or Script error"
    exit 3 #unknown
}