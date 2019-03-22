#Start Certificate Authority Console mmc
$mmcPath = "c:\Windows\System32\mmc.exe"
$mscPath = "c:\Windows\system32\certsrv.msc"
Start-Process -FilePath $mmcPath -ArgumentList $mscPath

## The `New-GP` command
## This will likely not be on the system you are using.
gcm New-GPO

## Createa a session to a domain controller
$session = New-PSSession -ComputerName dc01.lab.local -Credential (Get-Credential LAB\Administrator)

## Show the New-GPO command
Invoke-Command -Session $session -ScriptBlock { gcm New-GPO }

#Create New-GPO
Invoke-Command -Session $session -ScriptBlock {
    $comment = "AutoEnrolls Computers for the DscCert issued by the ADCS Cert server"
    New-GPO -Name Cert-AutoEnroll -comment $comment
}

#Change GPO Status
Invoke-Command -Session $session -ScriptBlock {
    (get-gpo "Cert-AutoEnroll").gpostatus="UserSettingsDisabled"
}

## mmc snippet to clip board
$strSnippet = @'
$mmcPath = "c:\Windows\System32\mmc.exe"
$mscPath = "c:\Windows\System32\gpmc.msc"
Start-Process -FilePath $mmcPath -ArgumentList $mscPath
'@
$strSnippet | Set-Clipboard


## rdp to domain controller (then go to ISE and paste)
mstsc /v:dc01.lab.local