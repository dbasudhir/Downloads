<#	
    .NOTES
    ===========================================================================
    Created with: 	ISE
    Created on:   	11/19/2019 1:46 PM
    Created by:   	Vikas Sukhija
    Organization: 	
    Filename:     	BulkPasswordReset.ps1
    ===========================================================================
    .DESCRIPTION
    This will reset the password for BUlk sam accountnames
#>
param (
  [string]$Password = $(Read-Host "Enter Password that will be Set"),
  [string]$Userlist = $(Read-Host "Enter Text file with Network accounts")

)

function Write-Log
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,ParameterSetName = 'Create')]
    [array]$Name,
    [Parameter(Mandatory = $true,ParameterSetName = 'Create')]
    [string]$Ext,
    [Parameter(Mandatory = $true,ParameterSetName = 'Create')]
    [string]$folder,
    
    [Parameter(ParameterSetName = 'Create',Position = 0)][switch]$Create,
    
    [Parameter(Mandatory = $true,ParameterSetName = 'Message')]
    [String]$Message,
    [Parameter(Mandatory = $true,ParameterSetName = 'Message')]
    [String]$path,
    [Parameter(Mandatory = $false,ParameterSetName = 'Message')]
    [ValidateSet('Information','Warning','Error')]
    [string]$Severity = 'Information',
    
    [Parameter(ParameterSetName = 'Message',Position = 0)][Switch]$MSG
  )
  switch ($PsCmdlet.ParameterSetName) {
    "Create"
    {
      $log = @()
      $date1 = Get-Date -Format d
      $date1 = $date1.ToString().Replace("/", "-")
      $time = Get-Date -Format t
	
      $time = $time.ToString().Replace(":", "-")
      $time = $time.ToString().Replace(" ", "")
	
      foreach ($n in $Name)
      {$log += (Get-Location).Path + "\" + $folder + "\" + $n + "_" + $date1 + "_" + $time + "_.$Ext"}
      return $log
    }
    "Message"
    {
      $date = Get-Date
      $concatmessage = "|$date" + "|   |" + $Message +"|  |" + "$Severity|"
      switch($Severity){
        "Information"{Write-Host -Object $concatmessage -ForegroundColor Green}
        "Warning"{Write-Host -Object $concatmessage -ForegroundColor Yellow}
        "Error"{Write-Host -Object $concatmessage -ForegroundColor Red}
      }
      
      Add-Content -Path $path -Value $concatmessage
    }
  }
} #Function Write-Log
function ProgressBar
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    $Title,
    [Parameter(Mandatory = $true)]
    [int]$Timer
  )
	
  For ($i = 1; $i -le $Timer; $i++)
  {
    Start-Sleep -Seconds 1;
    Write-Progress -Activity $Title -Status "$i" -PercentComplete ($i /10 * 100)
  }
}
#################Check if logs folder is created##################
$logpath  = (Get-Location).path + "\logs" 
$testlogpath = Test-Path -Path $logpath
if($testlogpath -eq $false)
{
  ProgressBar -Title "Creating logs folder" -Timer 10
  New-Item -Path (Get-Location).path -Name Logs -Type directory
}

$Reportpath  = (Get-Location).path + "\Report" 
$testlogpath = Test-Path -Path $Reportpath 
if($testlogpath -eq $false)
{
  ProgressBar -Title "Creating Report folder" -Timer 10
  New-Item -Path (Get-Location).path -Name Report -Type directory
}


####################Load variables and log#######################
$log = Write-Log -Name "BulkPasswordReset-Log" -folder "logs" -Ext "log"
$Report = Write-Log -Name "BulkPasswordReset-Report" -folder "Report" -Ext "csv"

$users = Get-Content $Userlist
$collection = @()
Write-Log -Message "Start Script" -path $log

########################Load Modules#############################
try{
  Import-Module ActiveDirectory
}
catch{
  $exception = $_.Exception
  Write-Log -Message "Error loading AD Module Loaded" -path $log -Severity Error
  Write-Log -Message $exception -path $log -Severity error
  ProgressBar -Title "Error loading AD Module Loaded - EXIT" -Timer 10
  Exit
}

########################Process users#############################
$SecurePassword=ConvertTo-SecureString $Password –asplaintext –force


$users | ForEach-Object{
  $error.clear()
  $mcoll = "" | Select UserID, PasswordReset
  $user = $_.trim()
  $mcoll.UserID = $user
  Write-Log -Message "Processing..............$user" -path $log
  Set-ADAccountPassword -Identity $user -Reset -NewPassword $SecurePassword
  Set-ADUser -Identity $user -ChangePasswordAtLogon $false
  if($error){
    Write-Log -Message "Password reset Failure $user " -path $log -Severity Error
    $mcoll.PasswordReset = "Error"
    $error.clear()
    
  }
  else{
    $mcoll.PasswordReset = "Success"
    Write-Log -Message "Password reset Success $user " -path $log
  }
  

  $collection+=$mcoll
}
$collection | Export-Csv $Report -NoTypeInformation
Write-Log -Message "Finish Script" -path $log

###########################################################################
# SIG # Begin signature block
# MIIhSAYJKoZIhvcNAQcCoIIhOTCCITUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUluKhLQm5htsBdTDpoxoSf2nd
# Fcmgghx8MIIGajCCBVKgAwIBAgIQAwGaAjr/WLFr1tXq5hfwZjANBgkqhkiG9w0B
# AQUFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVk
# IElEIENBLTEwHhcNMTQxMDIyMDAwMDAwWhcNMjQxMDIyMDAwMDAwWjBHMQswCQYD
# VQQGEwJVUzERMA8GA1UEChMIRGlnaUNlcnQxJTAjBgNVBAMTHERpZ2lDZXJ0IFRp
# bWVzdGFtcCBSZXNwb25kZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCjZF38fLPggjXg4PbGKuZJdTvMbuBTqZ8fZFnmfGt/a4ydVfiS457VWmNbAklQ
# 2YPOb2bu3cuF6V+l+dSHdIhEOxnJ5fWRn8YUOawk6qhLLJGJzF4o9GS2ULf1ErNz
# lgpno75hn67z/RJ4dQ6mWxT9RSOOhkRVfRiGBYxVh3lIRvfKDo2n3k5f4qi2LVkC
# YYhhchhoubh87ubnNC8xd4EwH7s2AY3vJ+P3mvBMMWSN4+v6GYeofs/sjAw2W3rB
# erh4x8kGLkYQyI3oBGDbvHN0+k7Y/qpA8bLOcEaD6dpAoVk62RUJV5lWMJPzyWHM
# 0AjMa+xiQpGsAsDvpPCJEY93AgMBAAGjggM1MIIDMTAOBgNVHQ8BAf8EBAMCB4Aw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDCCAb8GA1UdIASC
# AbYwggGyMIIBoQYJYIZIAYb9bAcBMIIBkjAoBggrBgEFBQcCARYcaHR0cHM6Ly93
# d3cuZGlnaWNlcnQuY29tL0NQUzCCAWQGCCsGAQUFBwICMIIBVh6CAVIAQQBuAHkA
# IAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBpAGMAYQB0AGUA
# IABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABhAG4AYwBlACAA
# bwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBDAFAAUwAgAGEA
# bgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5ACAAQQBnAHIA
# ZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABsAGkAYQBiAGkA
# bABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABvAHIAYQB0AGUA
# ZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBjAGUALjALBglg
# hkgBhv1sAxUwHwYDVR0jBBgwFoAUFQASKxOYspkH7R7for5XDStnAs0wHQYDVR0O
# BBYEFGFaTSS2STKdSip5GoNL9B6Jwcp9MH0GA1UdHwR2MHQwOKA2oDSGMmh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENBLTEuY3JsMDig
# NqA0hjJodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURD
# QS0xLmNybDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcnQwDQYJKoZIhvcNAQEFBQAD
# ggEBAJ0lfhszTbImgVybhs4jIA+Ah+WI//+x1GosMe06FxlxF82pG7xaFjkAneNs
# hORaQPveBgGMN/qbsZ0kfv4gpFetW7easGAm6mlXIV00Lx9xsIOUGQVrNZAQoHuX
# x/Y/5+IRQaa9YtnwJz04HShvOlIJ8OxwYtNiS7Dgc6aSwNOOMdgv420XEwbu5AO2
# FKvzj0OncZ0h3RTKFV2SQdr5D4HRmXQNJsQOfxu19aDxxncGKBXp2JPlVRbwuwqr
# HNtcSCdmyKOLChzlldquxC5ZoGHd2vNtomHpigtt7BIYvfdVVEADkitrwlHCCkiv
# sNRu4PQUCjob4489yq9qjXvc2EQwggbNMIIFtaADAgECAhAG/fkDlgOt6gAK6z8n
# u7obMA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0Rp
# Z2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0wNjExMTAwMDAwMDBaFw0yMTEx
# MTAwMDAwMDBaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IEFz
# c3VyZWQgSUQgQ0EtMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOiC
# LZn5ysJClaWAc0Bw0p5WVFypxNJBBo/JM/xNRZFcgZ/tLJz4FlnfnrUkFcKYubR3
# SdyJxArar8tea+2tsHEx6886QAxGTZPsi3o2CAOrDDT+GEmC/sfHMUiAfB6iD5IO
# UMnGh+s2P9gww/+m9/uizW9zI/6sVgWQ8DIhFonGcIj5BZd9o8dD3QLoOz3tsUGj
# 7T++25VIxO4es/K8DCuZ0MZdEkKB4YNugnM/JksUkK5ZZgrEjb7SzgaurYRvSISb
# T0C58Uzyr5j79s5AXVz2qPEvr+yJIvJrGGWxwXOt1/HYzx4KdFxCuGh+t9V3CidW
# fA9ipD8yFGCV/QcEogkCAwEAAaOCA3owggN2MA4GA1UdDwEB/wQEAwIBhjA7BgNV
# HSUENDAyBggrBgEFBQcDAQYIKwYBBQUHAwIGCCsGAQUFBwMDBggrBgEFBQcDBAYI
# KwYBBQUHAwgwggHSBgNVHSAEggHJMIIBxTCCAbQGCmCGSAGG/WwAAQQwggGkMDoG
# CCsGAQUFBwIBFi5odHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9zc2wtY3BzLXJlcG9z
# aXRvcnkuaHRtMIIBZAYIKwYBBQUHAgIwggFWHoIBUgBBAG4AeQAgAHUAcwBlACAA
# bwBmACAAdABoAGkAcwAgAEMAZQByAHQAaQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMA
# dABpAHQAdQB0AGUAcwAgAGEAYwBjAGUAcAB0AGEAbgBjAGUAIABvAGYAIAB0AGgA
# ZQAgAEQAaQBnAGkAQwBlAHIAdAAgAEMAUAAvAEMAUABTACAAYQBuAGQAIAB0AGgA
# ZQAgAFIAZQBsAHkAaQBuAGcAIABQAGEAcgB0AHkAIABBAGcAcgBlAGUAbQBlAG4A
# dAAgAHcAaABpAGMAaAAgAGwAaQBtAGkAdAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAA
# YQBuAGQAIABhAHIAZQAgAGkAbgBjAG8AcgBwAG8AcgBhAHQAZQBkACAAaABlAHIA
# ZQBpAG4AIABiAHkAIAByAGUAZgBlAHIAZQBuAGMAZQAuMAsGCWCGSAGG/WwDFTAS
# BgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGB
# BgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNl
# cnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMB0GA1UdDgQWBBQVABIr
# E5iymQftHt+ivlcNK2cCzTAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823I
# DzANBgkqhkiG9w0BAQUFAAOCAQEARlA+ybcoJKc4HbZbKa9Sz1LpMUerVlx71Q0L
# QbPv7HUfdDjyslxhopyVw1Dkgrkj0bo6hnKtOHisdV0XFzRyR4WUVtHruzaEd8wk
# pfMEGVWp5+Pnq2LN+4stkMLA0rWUvV5PsQXSDj0aqRRbpoYxYqioM+SbOafE9c4d
# eHaUJXPkKqvPnHZL7V/CSxbkS3BMAIke/MV5vEwSV/5f4R68Al2o/vsHOE8Nxl2R
# uQ9nRc3Wg+3nkg2NsWmMT/tZ4CMP0qquAHzunEIOz5HXJ7cW7g/DvXwKoO4sCFWF
# IrjrGBpN/CohrUkxg0eVd3HcsRtLSxwQnHcUwZ1PL1qVCCkQJjCCB24wggZWoAMC
# AQICExQAAGw7h27SJvtqjFYAAAAAbDswDQYJKoZIhvcNAQELBQAwajETMBEGCgmS
# JomT8ixkARkWA2NvbTEWMBQGCgmSJomT8ixkARkWBmJvc3NjaTEUMBIGCgmSJomT
# 8ixkARkWBGJzY2kxJTAjBgNVBAMTHEJTQ0ktRW50U3ViQ0EtUHJpdmF0ZS1TSEEy
# NTYwHhcNMTkwNjIwMTUyNDAzWhcNMjEwNjE5MTUyNDAzWjBsMQswCQYDVQQGEwJV
# UzESMBAGA1UECBMJTWlubmVzb3RhMRMwEQYDVQQHEwpTYWludCBQYXVsMQ0wCwYD
# VQQKEwRCU0NJMQswCQYDVQQLEwJJVDEYMBYGA1UEAxMPQ29sbGFiLkJzY2kuQ29t
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoxdVHu4+rS8DPNEMOl+0
# zw36DOnTWu4H7yC8oGO+VoXbhDBOF1YOxM4fDR683hlLuI71009WALi4hAK+VmkK
# DLpJd+MyJmj48rkycjJPOo4Ko5/bFDIArnAm0esZuVgKOxWn+HW4HIbhI1yv7koV
# Q8YWAsCUiV/nBSjOuzaui1LYU+Auox0BgnEuRm9pR1KPZGwAZveNx6BPlY6N3Y6Q
# h19KlzG3UwWuazmK6UNml3TZPJiR1L3MPXZ1tbpX2yidUBZmEDJVTHhmjCC32uqd
# ZxbIoKqsG0ZKTCVSxOxQj28QbqBOX7zk98P9BGOHf14whzi4AXyv06/TUL6Qd9+9
# uQIDAQABo4IECTCCBAUwHQYDVR0OBBYEFKClRhaHCgAHKaRLj/dP0FPjuE3qMB8G
# A1UdIwQYMBaAFGqRzcmwAsNJYfdzHN38XsLx9lVIMIIBZwYDVR0fBIIBXjCCAVow
# ggFWoIIBUqCCAU6GgcZsZGFwOi8vL0NOPUJTQ0ktRW50U3ViQ0EtUHJpdmF0ZS1T
# SEEyNTYsQ049bmF0Y2VydGFwMDIsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNl
# cnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9Ym9zc2NpLERD
# PWNvbT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2JqZWN0Q2xhc3M9
# Y1JMRGlzdHJpYnV0aW9uUG9pbnSGOmh0dHA6Ly9zaGVtcC5ic2NpLmNvbS9wa2kv
# QlNDSS1FbnRTdWJDQS1Qcml2YXRlLVNIQTI1Ni5jcmyGR2h0dHA6Ly9uYXRjZXJ0
# YXAwMi5ic2NpLmJvc3NjaS5jb20vcGtpL0JTQ0ktRW50U3ViQ0EtUHJpdmF0ZS1T
# SEEyNTYuY3JsMIIB2QYIKwYBBQUHAQEEggHLMIIBxzCBugYIKwYBBQUHMAKGga1s
# ZGFwOi8vL0NOPUJTQ0ktRW50U3ViQ0EtUHJpdmF0ZS1TSEEyNTYsQ049QUlBLENO
# PVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3Vy
# YXRpb24sREM9Ym9zc2NpLERDPWNvbT9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0
# Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTBvBggrBgEFBQcwAoZjaHR0cDov
# L25hdGNlcnRhcDAyLmJzY2kuYm9zc2NpLmNvbS9wa2kvbmF0Y2VydGFwMDIuYnNj
# aS5ib3NzY2kuY29tX0JTQ0ktRW50U3ViQ0EtUHJpdmF0ZS1TSEEyNTYuY3J0MGIG
# CCsGAQUFBzAChlZodHRwOi8vc2hlbXAuYnNjaS5jb20vcGtpL25hdGNlcnRhcDAy
# LmJzY2kuYm9zc2NpLmNvbV9CU0NJLUVudFN1YkNBLVByaXZhdGUtU0hBMjU2LmNy
# dDAzBggrBgEFBQcwAYYnaHR0cDovL25hdGNlcnRhcDAyLmJzY2kuYm9zc2NpLmNv
# bS9vY3NwMAsGA1UdDwQEAwIHgDA8BgkrBgEEAYI3FQcELzAtBiUrBgEEAYI3FQi5
# uyCBsYJIhe2DCIirDYLyulSBfYPIxneHlOBGAgFkAgEFMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwDQYJKoZIhvcNAQEL
# BQADggEBAJqRQ7eXQPbmXo1qeLWH0WyLgHa/jszsk8ojOulldLsC5uo/AtII06ql
# /251oR1VTvBieGFfp2CUpF6FaYQ4PAhNoftiro3rSxuWE1cAqNFLrpxmPjGR0Vk8
# r1O11+VyK1tiKXW+RL2rnA7FVeFt1K2K4eoG1eLkSy88jh6dP1QvQ18N8z6lxrLk
# viC19vN8kwGue4grE7yc+d69c0utfebLWPhK7cn4oeaNpgoy2DijjGFCgGGzSHCH
# rCg/GR3dZD9jkW8DfAxO9NFAw6+O8/2646ljDWEuBzgst+DfFg1zKFWqe2zHfvhR
# V7607Z7p6jrCoDsDi6Bi3pkKkRmAATwwggfHMIIFr6ADAgECAhN5AAAAApT+NAr/
# R95/AAAAAAACMA0GCSqGSIb3DQEBCwUAMCUxIzAhBgNVBAMTGkJTQ0ktUm9vdENB
# LVByaXZhdGUtU0hBMjU2MB4XDTE2MDIxNzE5MTIwOFoXDTI2MDIxNzE5MjIwOFow
# ajETMBEGCgmSJomT8ixkARkWA2NvbTEWMBQGCgmSJomT8ixkARkWBmJvc3NjaTEU
# MBIGCgmSJomT8ixkARkWBGJzY2kxJTAjBgNVBAMTHEJTQ0ktRW50U3ViQ0EtUHJp
# dmF0ZS1TSEEyNTYwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDHTOBg
# yph/ejsOJQs7O56AAKqmHMxdlxUhwwqwDGKnZ1fQVWLEcOz/egpFZQvyEJ16NmY4
# V1S/CwjspD0t9UyCjiFSiAFIYwFzdqOq1AD5zqLA2LtBgmqkxXjF5Ik/7hpmWBJz
# SWCw/O1WBf9WnM6+8G05kvB7Zef/tPr6SLAiuSrejUaY3ytEPi1uuPnH0UIXBTfZ
# o53B6XJQs92SmKEaVonvUCAO2Q+TuvyCYt37Cddqa9uNWXpRn1RYoXIMpWgRNeyE
# JPRnbljK1Jo/GM88IC9Ym1ArsWufkBXIN7HB1PH9XdYLrDJmaVsBdMaTrdpHIyUt
# 0bH+chGxuCESLG/hAgMBAAGjggOpMIIDpTAQBgkrBgEEAYI3FQEEAwIBADAdBgNV
# HQ4EFgQUapHNybACw0lh93Mc3fxewvH2VUgwggIXBgNVHSAEggIOMIICCjCCAgYG
# DCsGAQQBgvA1hAABBDCCAfQwTgYIKwYBBQUHAgEWQmh0dHA6Ly9uYXRjZXJ0YXAw
# Mi5ic2NpLmJvc3NjaS5jb20vUEtJL0ludGVybmFsVXNlLVBLSXBvbGljeS5odG1s
# ADCCAaAGCCsGAQUFBwICMIIBkh6CAY4ATABlAGcAYQBsACAAUABvAGwAaQBjAHkA
# IABTAHQAYQB0AGUAbQBlAG4AdAAgAC0AIABUAGgAaQBzACAAUABLAEkAIABpAHMA
# IABmAG8AcgAgAGkAbgB0AGUAcgBuAGEAbAAgAEIAbwBzAHQAbwBuACAAUwBjAGkA
# ZQBuAHQAaQBmAGkAYwAgAHMAeQBzAHQAZQBtAHMALgAgAFIAZQBmAGUAcgAgAHQA
# bwAgAHQAaABlACAAYQBzAHMAbwBjAGkAYQB0AGUAZAAgAEMAZQByAHQAaQBmAGkA
# YwBhAHQAZQAgAFAAcgBhAGMAdABpAGMAZQAgAFMAdABhAHQAZQBtAGUAbgB0ACAA
# KABDAFAAUwApACAAZgBvAHIAIABtAG8AcgBlACAAaQBuAGYAbwByAG0AYQB0AGkA
# bwBuAC4AIABBAG4AeQAgAG8AdABoAGUAcgAgAHUAcwBhAGcAZQAgAGkAcwAgAHMA
# dAByAGkAYwB0AGwAeQAgAHAAcgBvAGgAaQBiAGkAdABlAGQALjAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAf
# BgNVHSMEGDAWgBR8Z++utUb9qV0GMkqiieBN/wq12DBWBgNVHR8ETzBNMEugSaBH
# hkVodHRwOi8vbmF0Y2VydGFwMDIuYnNjaS5ib3NzY2kuY29tL3BraS9CU0NJLVJv
# b3RDQS1Qcml2YXRlLVNIQTI1Ni5jcmwwgaQGCCsGAQUFBwEBBIGXMIGUMF0GCCsG
# AQUFBzAChlFodHRwOi8vbmF0Y2VydGFwMDIuYnNjaS5ib3NzY2kuY29tL3BraS9u
# YXRjZXJ0YXAwMV9CU0NJLVJvb3RDQS1Qcml2YXRlLVNIQTI1Ni5jcnQwMwYIKwYB
# BQUHMAGGJ2h0dHA6Ly9uYXRjZXJ0YXAwMi5ic2NpLmJvc3NjaS5jb20vb2NzcDAN
# BgkqhkiG9w0BAQsFAAOCAgEArqWUBtTAwXctRrWSHI3nVFN4AIo74P0IrGKCODCv
# NtMXgLw0/eGT1aa2SaEnHMOk5sVi5nnR9Dol5JEiHWIZzxz8J8q5l0OdEpcorTRx
# B3jw1mjbrETMsERZHTr52SALZ2Ml5C03+3gJvfrO8R+DUcTleFXjhnLSQH3s59BF
# di4Rkvm3Y9XD226afgMaJSWEdUMxM5d4ld+IeUl65NJtUk2kpRawON+Y3pW98Pe7
# 9eaw/+udE9ZLa/HpM1/HRD38BDC4y2LJQ9v1UG94ylUfp77yMJT3qnB5Qtj9tZDw
# Qt2dZUbURiMvxvz3mBLjsMRCvrDdATHzjEYPT+rSQvFLqInG6p9T0iFoKIF7SzrR
# Q2PempyNm+l7kXTVP0EBP2+YSeM3GX8M1y/luYFAgGRRLNRAheF8rqe3eNeHR3ba
# CjwGw4pRTDqf5BTAQ3c9DsSNEw8/cj+suGiv7utqi3chxzWSTO9TlYs/Lnn8QJfD
# 0AboVftGEMQSKUgE9vXv28tjKgJN1zqGIuAcEZ7f9GXKRLODMhZ0Z/17qqGMd+HX
# vz1/OnxdvtaFA5V5VSueq4vOCOZ7wJE/ORQ54sPRIihY2kQabkBJArj7Omz60zYI
# YmrN+aFSrrt2Z8pq8Zu7QDHQfbrUgP6geZimB4ynlsqs9fSk+X9GSK0JUKpsacOq
# 4/4xggQ2MIIEMgIBATCBgTBqMRMwEQYKCZImiZPyLGQBGRYDY29tMRYwFAYKCZIm
# iZPyLGQBGRYGYm9zc2NpMRQwEgYKCZImiZPyLGQBGRYEYnNjaTElMCMGA1UEAxMc
# QlNDSS1FbnRTdWJDQS1Qcml2YXRlLVNIQTI1NgITFAAAbDuHbtIm+2qMVgAAAABs
# OzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG
# 9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIB
# FTAjBgkqhkiG9w0BCQQxFgQUJfEHlZZYfwbg2NkCNARf97rp7sswDQYJKoZIhvcN
# AQEBBQAEggEAOA3tANYrwv+hSLImTPmUFU3Le+TbJ2ZqhEcNNLe07znUVRD287M2
# vXhqL5NPk3atSIGPKdsTLZ7CiUJkQSwrU4QIUtXukXGicVCdIIloCdyKKnXAQcdL
# Decq/Edo+El0YfFpMExgVap+iYDMvbcU7U98/+5wNUp085LIY9yyKmX9NOwwdBax
# DZpgBcqCaQRHU3/WDathTqHvfYgrIM97vWyGmees3L8Xknap9mcXOKZOrlupvRw9
# C8SvOXTDkwU0kpS8dR3jJFgGgxJrLBNWkEgMDSwg1ppcF37mVvkgsNuxJxycnH+N
# Da/SUVfcbCXvV2OVvOnPCEy6c+N3mZeR5KGCAg8wggILBgkqhkiG9w0BCQYxggH8
# MIIB+AIBATB2MGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IEFz
# c3VyZWQgSUQgQ0EtMQIQAwGaAjr/WLFr1tXq5hfwZjAJBgUrDgMCGgUAoF0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkxMTE5MTcy
# NDU2WjAjBgkqhkiG9w0BCQQxFgQUorgyqyz3ZCSM+cAuYyAMZ+Xc6sEwDQYJKoZI
# hvcNAQEBBQAEggEAPO7bT6oOvGJHUGqxL8FN1kv8o50MHj1f76CEpeg9pLhBN3zB
# wg+K8q9jrEPgUN/G8oGRFV8Ou64krTi+6WiuoCpl3nm8Nu25kJCTD3IVJ6N7qLXp
# VoIfjgCkKH2yyA/grhDywEnMQywA7JqApo9scL/ZQedVzDWDA7+ZogCgRb38vd99
# C2iF2uLcCdDzzNpPhrKmAi5bPoy4Z0ZL/ySoR4nxz+lTC/UWFdiVhermlGpJ6xZd
# PL5/yPiB6L9JYszJw7jhtiwql1qeft7pnq/1bZe0cbePaR5uPMaakDVutwsWf3ug
# Wy2hVfscEVD1A8UbLZkrE50CUQfBp1zviOAx2Q==
# SIG # End signature block
