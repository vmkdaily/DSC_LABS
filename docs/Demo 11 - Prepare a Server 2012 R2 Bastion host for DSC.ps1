## How to prepare a Server 2012 R2 Bastion host for DSC

## Tasks performed here:
## Connect to guest, add module support for certs, create a self-signed cert, and save the cert locally to authoring machine.

#Note: An authoring machine can be your client (laptop/desktop/jump server) or a real dsc pull server.

## Session setup
$error.clear();Clear-Host
$guest = '10.205.1.151'  #IP Address or name of guest node to manage.
$creds = Get-Credential "$guest\Administrator"
$session = New-PSSession -ComputerName $guest -Credential $creds

## Show session
$session

#Note: If you get red text when creating session, then check WinRM trusted host list:
psedit "C:\DSC_LABS\docs\Demo 6 - How to handle WinRM trusted hosts.ps1"

#Note: If still having issues connecting, ensure that "winrm quickconfig" has been run.
psedit "C:\DSC_LABS\docs\Demo 5 - How to run a script on a remote Guest with PowerCLI.ps1"

## Show version of os; we expect version 6 for 2012 R2.
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

## Determine PowerShell version of remote node. Expect to see PowerShell 5.1.
## Note that PowerShell 4.0 is plaintext, so WMF 5 is required for encryption by default.
Invoke-Command -Session $session -ScriptBlock {
  $PSVersionTable.PSVersion
}

## Optional - Configure remote node proxy (sets the IE proxy)
psedit "C:\DSC_LABS\docs\Quick Task - How to configure remote node proxy server for PSGallery (optional).ps1"

## Install the PSPKI module on remote guest using gallery
Invoke-Command -Session $session -ScriptBlock {
    
  Find-Module -Name PSPKI | Install-Module -Confirm:$false
}

## Or, copy the module with Copy-Item, see:
psedit "C:\DSC_LABS\docs\Demo 8 - How to use Copy-Item on PowerShell 5 to copy a module for use with DSC.ps1"

## Confirm module exists on remote guest
Invoke-Command -Session $session -ScriptBlock {
  Get-Module -Name PSPKI -ListAvailable
}

## Optional - Get list of existing certs. Expect none.
Clear-Host
$existingCerts = Invoke-Command -Session $session -ScriptBlock {
  Get-ChildItem Cert:\LocalMachine\my
}

## Show existing cert count. Expect 0.
Write-Host ('Found {0} existing cert(s)' -f $existingCerts.count) -ForegroundColor Magenta

## Show existing certs. Expect none.
$existingCerts

## Variables for new certificate to create
[string]$Subject = ('CN={0}' -f $session.ComputerName)
[string]$StoreLocation = 'LocalMachine'
[string]$KeyUsage  = 'KeyEncipherment'
[string]$EnhancedKeyUsage =  '1.3.6.1.4.1.311.80.1'
[string]$FriendlyName = 'DscBastionCert'
[datetime]$NotBefore = [datetime]::now.AddDays(-1)
[datetime]$NotAfter = [datetime]::now.AddDays(1)  #more common would be AddYears(1)
[string]$SignatureAlgorithm = 'SHA256'

## Create cert on remote guest with New-SelfSignedCertificateEx
Invoke-Command -Session $session -ScriptBlock {
  
  #show computername
  Write-Host "Creating certificate on " -NoNewline
  cat env:COMPUTERNAME
  
  #import module
  $null = Import-Module PSPKI
  
  #create cert
  New-SelfSignedCertificateEx `
  -Subject $Using:Subject `
  -StoreLocation $Using:StoreLocation `
  -KeyUsage $Using:KeyUsage `
  -EnhancedKeyUsage $Using:EnhancedKeyUsage `
  -FriendlyName $Using:FriendlyName `
  -NotBefore $Using:NotBefore `
  -NotAfter $Using:NotAfter `
  -SignatureAlgorithm $Using:SignatureAlgorithm `
  -Verbose:$true
}

## Get any valid local cert. You can get more specific by using FriendlyName or similar (not shown here).
$cert = Invoke-Command -Session $session -ScriptBlock {
    [string]$strName = cat env:ComputerName
    Get-ChildItem Cert:\LocalMachine\my | Where-Object { $_.PrivateKey.KeyExchangeAlgorithm }
}

## Show the cert
$cert  |fl *

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
Export-Certificate -Cert $cert -FilePath "$localCertPath\$guest.cer" -Force

## List cert folder contents
$localCertPath = "C:\Certs"
Get-ChildItem $localCertPath

## Explore your certs directory
$localCertPath = "C:\Certs"
start Explorer $localCertPath

## Next, see the document LCM_DscBastion to create a local configuration.
psedit C:\DSC_LABS\LCM_DscBastion.ps1

## Summary
## In this demo, we prepared a Windows Server 2012 R2 bastion host for dsc.

## Next, we learn how to promote a domain controller and create a domain for lab.local: 
psedit "C:\DSC_LABS\docs\Demo 12 - How to create a domain controller and domain with dsc.ps1"