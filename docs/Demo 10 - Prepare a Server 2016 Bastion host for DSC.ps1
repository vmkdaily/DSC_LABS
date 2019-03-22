## Example - Prepare a Server 2016 Bastion host for DSC

## Session setup
$error.clear();clear
$guest = '10.205.1.153'  #IP Address or name of guest node to manage.
$creds = Get-Credential $guest\Administrator
$session = New-PSSession -ComputerName $guest -Credential $creds

## Confirm session is active
$session

#Note: If you get red text when creating session, then check WinRM trusted host list:
psedit "C:\DSC_LABS\docs\Demo 6 - How to handle WinRM trusted hosts.ps1"

#Note: If still having issues connecting, ensure that "winrm quickconfig" has been run.
psedit "C:\DSC_LABS\docs\Demo 5 - How to run a script on a remote Guest with PowerCLI.ps1"

## Confirm PKI support on remote node
$osVersionMajor = Invoke-Command -Session $Session -ScriptBlock { [Environment]::OSVersion.Version.Major }
switch($osVersionMajor){
  '10' {
    Write-Host 'Detected OS major version of 10 (supports official PKI module!)' -ForegroundColor Green -BackgroundColor DarkGreen
    return $osVersionMajor
  }
  '6'{
    Write-Host 'Detected OS major version of 6 or less (supports PSPKI community module only!)' -ForegroundColor Yellow -BackgroundColor DarkYellow
    return $osVersionMajor
  }
}

## Determine PowerShell version of remote node.
Invoke-Command -Session $session -ScriptBlock {
    $PSVersionTable
}

## Create cert on remote node
Invoke-Command -Session $Session -ScriptBlock {
  New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscBastionCert' -HashAlgorithm SHA256
}

## Get the cert, for bastion guests. If in the domain or already part of dsc, then you may want some other cert instead.
$cert = Invoke-Command -Session $session -ScriptBlock {
    Get-ChildItem Cert:\LocalMachine\my | Where-Object {
      ($_.DnsNameList -eq 'DscBastionCert') `
      -and $_.PrivateKey.KeyExchangeAlgorithm
    }
}

## Show the cert
$cert

## Show the cert, detailed
$cert |fl *

## Extract thumbprint
$thumbprint = $cert.thumbprint

##Show thumbprint
$thumbprint

## Create local folder for certs if needed
$localCertPath = "C:\Certs"
If(-Not(Test-Path -Path $localCertPath -PathType Container -ea 0)){
  Write-Host "Creating $($localCertPath)!" -ForegroundColor Yellow -BackgroundColor DarkYellow
  New-Item -ItemType Directory -Path $localCertPath -Force
}
Else{
  Write-Host "Using existing folder $($localCertPath) for certs!" -ForegroundColor Green -BackgroundColor DarkGreen
}

## Export the cert on your client (or authoring machine)
$localCertPath = "C:\Certs"
Export-Certificate -Cert $cert -FilePath "$localCertPath\$guest.cer" -Force

## List cert folder contents
$localCertPath = "C:\Certs"
Get-ChildItem $localCertPath

## Next, learn to prepare a Server 2012 R2 or older host
psedit "C:\DSC_LABS\docs\Demo 11 - Prepare a Server 2012 R2 Bastion host for DSC.ps1"


############
## APPENDIX
############

## Optional - Learn how to create a dsc local configuration for the remote node.
psedit "C:\DSC_LABS\LCM_DscBastion.ps1"

## Optional - If you have a pull server already, see:
psedit "C:\DSC_LABS\LCM_HTTPSPULL.ps1"

##Learn the ethernet adapter name of a remote node
$ethernet = Invoke-Command -Session $session -ScriptBlock {
    (Get-NetAdapter | Where-Object {$_.Name -eq 'Ethernet0' -or  $_.Name -eq 'Internal'}).Name
}

#Show the results
$ethernet