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
Boolean parameter to either include (1) expired certificates with a warning status, or exclude (0) expired certificates. Default 0

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
    [bool]$e = 0
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
# SIG # Begin signature block
# MIIv8wYJKoZIhvcNAQcCoIIv5DCCL+ACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBkoTlLAcIj4OUR
# Z3C6mMePeFfcHBLYz4aBK6yn6dnFuKCCJwowggVvMIIEV6ADAgECAhBI/JO0YFWU
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggWNMIIEdaADAgECAhAOmxiO
# +dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAi
# BgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAw
# MDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERp
# Z2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCC
# AgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsb
# hA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iT
# cMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGb
# NOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclP
# XuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCr
# VYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFP
# ObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTv
# kpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWM
# cCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls
# 5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBR
# a2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6
# MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qY
# rhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8E
# BAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDig
# NoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9v
# dENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCg
# v0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQT
# SnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh
# 65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSw
# uKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAO
# QGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjD
# TZ9ztwGpn1eqXijiuZQwggYaMIIEAqADAgECAhBiHW0MUgGeO5B5FSCJIRwKMA0G
# CSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExp
# bWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBSb290
# IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5NTlaMFQxCzAJBgNVBAYT
# AkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28g
# UHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0GCSqGSIb3DQEBAQUAA4IB
# jwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjIztNsfvxYB5UXeWUzCxEe
# AEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NVDgFigOMYzB2OKhdqfWGV
# oYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/36F09fy1tsB8je/RV0mIk
# 8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05ZwmRmTnAO5/arnY83jeNzh
# P06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm+qxp4VqpB3MV/h53yl41
# aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUedyz8rNyfQJy/aOs5b4s+
# ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz44MPZ1f9+YEQIQty/NQd/
# 2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBMdlyh2n5HirY4jKnFH/9g
# Rvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQYMBaAFDLrkpr/NZZILyhA
# QnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritUpimqF6TNDDAOBgNVHQ8B
# Af8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUEDDAKBggrBgEFBQcD
# AzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsGA1UdHwREMEIwQKA+oDyG
# Omh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5n
# Um9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsGAQUFBzAChjpodHRwOi8v
# Y3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ1Jvb3RSNDYu
# cDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG
# 9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURhw1aVcdGRP4Wh60BAscjW
# 4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0ZdOaWTsyNyBBsMLHqafvIh
# rCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajjcw5+w/KeFvPYfLF/ldYp
# mlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNcWbWDRF/3sBp6fWXhz7Dc
# ML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalOhOfCipnx8CaLZeVme5yE
# Lg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJszkyeiaerlphwoKx1uHRz
# NyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z76mKnzAfZxCl/3dq3dUNw
# 4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5JKdGvspbOrTfOXyXvmPL6
# E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHHj95Ejza63zdrEcxWLDX6
# xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2Bev6SivBBOHY+uqiirZt
# g0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/L9Uo2bC5a4CH2Rwwggau
# MIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAe
# Fw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbSg9Ge
# TKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9/UO0
# hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXnHwZl
# jZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0VAsh
# aG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4fsbVY
# TXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40NjgHt1
# biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0QCir
# c0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvvmz3+
# DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T/jnA
# +bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk42Pg
# puE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5rmQzS
# M7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU
# uhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6
# mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsG
# AQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29t
# MEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNl
# cnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3Js
# My5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAE
# GTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAH1Z
# jsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxpwc8d
# B+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIlzpVp
# P0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQcAp8
# 76i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfeKuv2
# nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+jSbl3
# ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJshIUDQ
# txMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6OOmc
# 4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDwN7+Y
# AN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR81fZ
# vAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2VVQr
# H4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIGwDCCBKigAwIBAgIQDE1p
# ckuU+jwqSj0pB4A9WjANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUG
# A1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQg
# RzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTIyMDkyMTAwMDAw
# MFoXDTMzMTEyMTIzNTk1OVowRjELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERpZ2lD
# ZXJ0MSQwIgYDVQQDExtEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMiAtIDIwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDP7KUmOsap8mu7jcENmtuh6BSFdDMa
# JqzQHFUeHjZtvJJVDGH0nQl3PRWWCC9rZKT9BoMW15GSOBwxApb7crGXOlWvM+xh
# iummKNuQY1y9iVPgOi2Mh0KuJqTku3h4uXoW4VbGwLpkU7sqFudQSLuIaQyIxvG+
# 4C99O7HKU41Agx7ny3JJKB5MgB6FVueF7fJhvKo6B332q27lZt3iXPUv7Y3UTZWE
# aOOAy2p50dIQkUYp6z4m8rSMzUy5Zsi7qlA4DeWMlF0ZWr/1e0BubxaompyVR4aF
# eT4MXmaMGgokvpyq0py2909ueMQoP6McD1AGN7oI2TWmtR7aeFgdOej4TJEQln5N
# 4d3CraV++C0bH+wrRhijGfY59/XBT3EuiQMRoku7mL/6T+R7Nu8GRORV/zbq5Xwx
# 5/PCUsTmFntafqUlc9vAapkhLWPlWfVNL5AfJ7fSqxTlOGaHUQhr+1NDOdBk+lbP
# 4PQK5hRtZHi7mP2Uw3Mh8y/CLiDXgazT8QfU4b3ZXUtuMZQpi+ZBpGWUwFjl5S4p
# kKa3YWT62SBsGFFguqaBDwklU/G/O+mrBw5qBzliGcnWhX8T2Y15z2LF7OF7ucxn
# EweawXjtxojIsG4yeccLWYONxu71LHx7jstkifGxxLjnU15fVdJ9GSlZA076XepF
# cxyEftfO4tQ6dwIDAQABo4IBizCCAYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB
# /wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwB
# BAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshv
# MB0GA1UdDgQWBBRiit7QYfyPMRTtlwvNPSqUFN9SnDBaBgNVHR8EUzBRME+gTaBL
# hklodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0
# MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAC
# hkxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRS
# U0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4IC
# AQBVqioa80bzeFc3MPx140/WhSPx/PmVOZsl5vdyipjDd9Rk/BX7NsJJUSx4iGNV
# CUY5APxp1MqbKfujP8DJAJsTHbCYidx48s18hc1Tna9i4mFmoxQqRYdKmEIrUPwb
# tZ4IMAn65C3XCYl5+QnmiM59G7hqopvBU2AJ6KO4ndetHxy47JhB8PYOgPvk/9+d
# EKfrALpfSo8aOlK06r8JSRU1NlmaD1TSsht/fl4JrXZUinRtytIFZyt26/+YsiaV
# OBmIRBTlClmia+ciPkQh0j8cwJvtfEiy2JIMkU88ZpSvXQJT657inuTTH4YBZJwA
# wuladHUNPeF5iL8cAZfJGSOA1zZaX5YWsWMMxkZAO85dNdRZPkOaGK7DycvD+5sT
# X2q1x+DzBcNZ3ydiK95ByVO5/zQQZ/YmMph7/lxClIGUgp2sCovGSxVK05iQRWAz
# gOAj3vgDpPZFR+XOuANCR+hBNnF3rf2i6Jd0Ti7aHh2MWsgemtXC8MYiqE+bvdgc
# mlHEL5r2X6cnl7qWLoVXwGDneFZ/au/ClZpLEQLIgpzJGgV8unG1TnqZbPTontRa
# mMifv427GFxD9dAq6OJi7ngE273R+1sKqHB+8JeEeOMIA11HLGOoJTiXAdI/Otrl
# 5fbmm9x+LMz/F0xNAKLY1gEOuIvu5uByVYksJxlh9ncBjDCCCG4wggbWoAMCAQIC
# EQDSAz5Wchs+/saB924ihzrPMA0GCSqGSIb3DQEBDAUAMFQxCzAJBgNVBAYTAkdC
# MRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVi
# bGljIENvZGUgU2lnbmluZyBDQSBSMzYwHhcNMjMwMzA5MDAwMDAwWhcNMjYwMzA4
# MjM1OTU5WjBoMQswCQYDVQQGEwJVUzETMBEGA1UECAwKV2FzaGluZ3RvbjEhMB8G
# A1UECgwYVW5pdmVyc2l0eSBvZiBXYXNoaW5ndG9uMSEwHwYDVQQDDBhVbml2ZXJz
# aXR5IG9mIFdhc2hpbmd0b24wggQiMA0GCSqGSIb3DQEBAQUAA4IEDwAwggQKAoIE
# AQC3Bh8AVCNeOqtzQRmMC1s4vTtUIud8Dn5RwQmW73wrxDCnTniskwlGzUwrHRx/
# kxRoGTyYsFD9nt1zsNz96a37QgU0n7HFwk5gzgg+1SINYUdNd4VJ4ZVu5GfEA47E
# BadvSJuLn92Y0NLhIx2lAFanSEBR23FwBxxKcC/R8bblxrp4EFsbzWfCmmgQ7ICl
# YBjqIP9nJGYsgITclkEs8q9LnRJghU+A7+kCpHN34J9nqzwyPtwrky2aRscV4mkY
# YwHWy2FH7aM1+b5BxnTcl9qpJrn8J1N3tBzGZnDCWp1F2VcK1JaKDANOikRSF7JL
# BKKkJy24wf7rx5bxJBvcer/a58QhJfz9LgIyFxOUAMSQ2ICgVeZeWFqrtNIpU+mv
# CbZ7os1+KuBzY6Uvf6fhFHGeX6JjYpTCeAiA6h+3G0E/ft3xMGqZEMTIC/fSl7b5
# +UW9BYZ6CQ+nz5jpS/t0E6HBymC0EYfTHlcpLot75I3E0LmZ+md1q2XSG5AP8meX
# Az5X3B+0DPJ5xcgNfBdjq16hBG4vb8fdBkoCHxXxMncs3p6D169Yv3F2a2KC6hVO
# ywat+v9+mlYO1uPQgKHfr2ICHiqtV22lGvuRNyqC4JXohNHTiThN84Qlt8ls9JfN
# gkEdMHKiirjr/GhGbn8Y7fLvRujWAizrJG7e+arnX1YQigk6xIADt9GfNmipHL32
# 6w2XZZOkHD9ExkmAexwy7qrJ5WGi9kK8eoqe2Uim7P40/is1GQWo++T1EjKRQc/H
# ujBcszI8z5izaqq6q4Bbcuo0j9O0KNFf+8mhrrjXJ79jL4FmByWtVX5AGtWntHOo
# vmCc3hRkYDSLHK16DKUXQzJZLQb6DK7864iWl08N484yCNUXWZ1jQYXievaVHwSG
# YAmVg71p7w3oCa3uPlACOQA7AKjVDUqwbtCOug1jlUDrKhEXLmzcwr8g8gaqUbkD
# MFlvhxyM/cfsZq3k9Cf79Llji4vPChIIF6yQlZfbE53nFYzufcVqJ6hHWReohcUG
# NLBN+Z4PqLkKPt3O/RPrFOpPuE3B+VAbCIqbL9P8FGqvdAfIu9ZU4WE35hJwQX9m
# KoUOaCN1CHeCCnx/aZJLa8tO03a9mWigWtsFgAeP6R6je27pX+CPf/+I9AfiD6oP
# jlNJvSZTbC/A0+lnAFkwZTvfkEZ1eTd3sr/NOSFWLUufLm4pQWEEszjfQzHkUUZu
# HYPN70NGvDmvunWh5ASYSBB4XM+oPXW8rULSNdfIUA9S5Rrz8FgT1LvzA0IPfwVO
# PnxGfmrKqCu56I0S/CI+cCMag1SQIPCSeOHtmAtdw++t+pvcjleYZTj2CUy/zk0K
# L/EetDsTCdbCCq0ay/4wHx9ZAgMBAAGjggGlMIIBoTAfBgNVHSMEGDAWgBQPKssg
# hyi47G9IritUpimqF6TNDDAdBgNVHQ4EFgQUib2YKHQBG4qMFS5OjRERO+mr8Icw
# DgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUH
# AwMwSgYDVR0gBEMwQTA1BgwrBgEEAbIxAQIBAwIwJTAjBggrBgEFBQcCARYXaHR0
# cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQQBMEkGA1UdHwRCMEAwPqA8oDqG
# OGh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5n
# Q0FSMzYuY3JsMHkGCCsGAQUFBwEBBG0wazBEBggrBgEFBQcwAoY4aHR0cDovL2Ny
# dC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdDQVIzNi5jcnQw
# IwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMBoGA1UdEQQTMBGB
# D2FodmFrYW5hQHV3LmVkdTANBgkqhkiG9w0BAQwFAAOCAYEAMuyieccFLJxq2OsH
# 6U6MtACCcLCIjx4ehXH3MMu91XOARmFgHnwKQraPf2enRi/4GhTX/PDVd48ududc
# 8pWbqzysXYGNOqxWGw9OEOK0zoReaEUDavK3E6ZdeguF1SS6GNPQbgd+o77zkRBZ
# m8LgCxpPDVSpeF0rT5Hi0ebyEpIkTbQ8goFlrQi3UUjlTUUmmpixgjysZ0oQfKos
# cpVoRVPEtvHkgBBnITnl1StXYVkyHpmzG56CT6dKXhVDXs89LMEPE1O0jJFKjCwH
# BdDu5/MWki0HxbEs+ueKhLDLYLj4mRlrxQT401LW/JitCahgDdDPeEB001SiVx7z
# sHRdEG4rvy9UIO06oiC5LRB51Mdpm425VU+ENihjMNZIvn8D4B8TxqgSKH8DRW7p
# qjDeJEFtx9UHskMGuuLhDC7HSakNGS5KOjEQAGGagShkB+BQGCiQdEddDXFA8/27
# zaI9L6ivNSEMD1G6wdQ1YJDr1eJInpUsQKHCMkeinYoZnjn/MYIIPzCCCDsCAQEw
# aTBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYD
# VQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhEA0gM+VnIb
# Pv7GgfduIoc6zzANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKAC
# gAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsx
# DjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCWzoRP5EyqenA8oKfl2/lp
# 5OW17ta/T8S0mgC7d7BzcTANBgkqhkiG9w0BAQEFAASCBABDhmv4zbIo5uvotRIz
# tSWfFn8GETQBwGlTJVWO+VLOF24988hrvvATz71R/6T8Y1QRw/MvfpKULgiqpLT2
# MR7LflqHCVMaQ/WKglg7EoTwyQii+CLH+aeQBN6EpHROUBh4n+ejRm/IRLaVV1UD
# RkNCYIzQEmm+tCcv/Xoz+DAFZ+D71C7l4CAMRGcvGPrciEjk64Au7me6f3CAt6wR
# BrtO/hLztg4P+IRoOv5GVnfU4kTS1JiVfeTn60wyZ99tz+2Qt8gEOOyQYwkdh56L
# Pc7weY8Zjx8sXoNgUO4awmz8+xDHokmVeXk4QcqvSqKMDZLPvWPDqcAF7HkD8XNL
# 5Y3hWYn82vB0+O7vV/CPYdaTYtsCruqlDwMXu2DBbtUZTktqNF6m7uCIbvtix/6V
# 49CXcO2u5Y82iYjQym4Yr1Pxsuc13BmlKHAtg1TpnugC47z0XvUh2NCwkR1c7rGY
# P+TckoxIolfuNGg8fcpm7TNzktsehhgKXAO9OnltAmuV7K9OkajCnEAxUJYaYpjh
# P/uvNZ7IxEjawZeekrmaaJpBZrMtHEUDsY/VLZSUtiglMRKX/lzuJuU1rybep0kb
# jFSWrOyq/YPKm7ONF0fRPEDSJBMz0nMeHi3NEXLv+A2SejZSNwKGRgH7Iz5KHnq2
# DRZHk5dcSLdv+PNILNzgjMygPGsUILyDFtCFekPwJlwaIESAO/JyBVaW8579y5Vz
# a2TadOMahWffpcgE4KAzpq9hnMCcnkRNlajFVitRyVzGuW4VMS5eR7Vix/lSZuMt
# QIFH1TRCRSZuVD9Jj8ddN8vJk+1lhgd4eQ0Az3D+NiE0HrpuZgCDL2zQjofd1drG
# C8jPINcUwxj3ZH4Hh2ilXYyJZVrd5Rf92ODzA6lJl8SNC2ROsbKRfbgnqdRJ5spU
# KCNCDcqPWzcPuU5G34zCvdcPA+Rup5edq8MFYpGZF6wJ3a8L5YOu7kkwKar3lTHQ
# fWEXHJ6efRzTxjdpLQTbK0amo8/RCyAgk6niWfUHAmZvZ/ZmG5+Xyp4KUZ1hdZcW
# srV46Etrsjmsd+W6bhV29qnOk9wrt6YgjAaQU2mi7QBxnsdDPjT72CKAXUxGshwD
# 8YIeEB+Z6NQvSx89PanX+aIaXxIIstzyTQrYeds/tZfzSED/5XJj/uYAM2fFEOAR
# Fr76fmKhJ/CP5t3aCfdydskVXPh+bYi7l9QvXoO1wCR31rB3ddU+LEV0Ohq++nUj
# jg5LJJYrD7CCELBPwZwE6XnhYnSPnw670JtGeHVkHq2PJjx5zcaisFhU0z2uIkIn
# zOs/zog+88yGtv+wAZBN7xOYOGUVGjzGp8lMXMu/59PbCNIrmv3RGEr6qLhrjrMb
# d3AYoYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJAgEBMHcwYzELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBU
# cnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQQIQDE1pckuU
# +jwqSj0pB4A9WjANBglghkgBZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG
# 9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIzMDMxMDAyMDk1MFowLwYJKoZIhvcNAQkE
# MSIEIMvdZAkskvALpVlDqHIqWU4XSTRLTXlGWUfs9096kuSDMA0GCSqGSIb3DQEB
# AQUABIICAGeHugrvmTq2twuzCJgghJ7MZlvTZ92J0UokA4Ycz69j0iamOqKBRg3i
# 4fs9rKNllUAjWbZDvRGZJvmTqy9kbg+T9zwiczIOaRGIGNJNOQw3s1wUKB3aARvh
# rEC5228qZWBQA0nghFgob5e1C5nN2MrL+YngL03xezzEadUMPWr/UajARdF37wKj
# 1mpKw3ZPrGOPz2BmTqoO+owT9+a1OCU7bdUIcWc1w8P6us8NHQ9BLYeKQlTWzqpn
# xWLCSxdUkFlY4To+SWj6G3Nksu8FT22ppfsjwQbMO8JN1VAy4wRzpxUrT2Gqefyt
# PXaT+YCT3KQujLdIGrOayOsPtotpnu5j1PF5Tj00N/gKVxwL69LxgYON5LluZnLx
# CqnbQUPaoPfR8kTyPJaBi6cEWhP0TQ/YYf/4N2so00Jjt9uOfFGXj2JlcGj+LocS
# +K4qQaa9g/UFB0YdBSpt1Cw6Fyc5143F8MgJyUUaxk4NQZrfF10fazzvlfHei42t
# IT5RVMafyIVVzKemgM02fTP6wPw09m3RIozFMs7UyOnptxWPEfYWgLqaTLllPYKG
# X4ouSaorLTpPl4mkXUVHIk6Cjhvw66D5dzgAJ3QcN1brdnpq0h28fjJTd54wMTtR
# otX6fQxci9FAfH9TBGOsAz9SrfgrU9UYj23H0822EH5PU1JPGNvE
# SIG # End signature block
