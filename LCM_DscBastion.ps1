[DSCLocalConfigurationManager()]
Configuration LCM_DscBastion
{
    param
        (
            [Parameter(Mandatory=$true)]
            [string[]]$ComputerName,

            [Parameter(Mandatory=$true)]
            [string]$Guid,

            [Parameter(Mandatory=$true)]
            [string]$Thumbprint

        )
  Node $ComputerName {

    Settings {

      AllowModuleOverwrite = $True
      ConfigurationMode = 'ApplyAndAutoCorrect'
      RefreshMode = 'Push'
      ConfigurationID = $guid
      CertificateID = $thumbprint
    }
  }
}

#Run the above to add as a function.

## Always do this part. DSC will use CIM.
$ComputerName = '10.205.1.151'
$creds = Get-Credential -UserName ('{0}\Administrator' -f $ComputerName) -Message 'Enter login password'
$cim = New-CimSession -ComputerName $ComputerName -Credential $creds

## Show cim session
$cim

## get remote cert, if needed.
$cert = Invoke-Command -ScriptBlock {
     Get-ChildItem Cert:\LocalMachine\my | Where-Object {$_.DnsNameList -eq $Using:ComputerName -or $_.DnsNameList -eq 'DscBastionCert'}
} -ComputerName $ComputerName -Credential $creds

## Show remote cert
$cert | fl *

## Thumbprint
$Thumbprint = $cert.Thumbprint

## Show thumbprint
$Thumbprint

## New guid
$guid=[guid]::NewGuid()

## show guid (optional)
$guid

## create the meta mof
LCM_DscBastion -ComputerName $ComputerName -Guid $guid -Thumbprint $Thumbprint -OutputPath C:\dsc\$Computername

## view the meta mof (optional)
psedit C:\dsc\$Computername

## Set the LCM on remote guest
Set-DscLocalConfigurationManager -CimSession $cim -Path C:\dsc\$ComputerName -Verbose

## Get DSC config on remote guest
Get-DscLocalConfigurationManager -CimSession $cim

## Summary
## This has been a fully secure dsc config for a bastion host.

###################################
## APPENDIX - Removing a cert
###################################

## Optional - Remove all certs in `my` on the remote guest; Only for test environments.
## After this you would also delete the .cer from your client or authoring machine.
$ComputerName = '10.205.1.151'
$creds = Get-Credential -UserName ('{0}\Administrator' -f $ComputerName) -Message 'Enter login password'
Invoke-Command -ScriptBlock {
     Get-ChildItem Cert:\LocalMachine\my | Remove-Item
} -ComputerName $ComputerName -Credential $creds

