#######################################
## handle nodes with DscBastionCert
#######################################

## Introduction
<#
At this point in the lab dsc setup, we are ready to manage some nodes with dsc.
For the test node, we assume that a self-signed certificate was generated already.
Here we gather information we can use when creating the lcm later for this node.
#>

$ComputerName = 's1'
$creds = Get-Credential $ComputerName\Administrator
$session = New-PSSession -ComputerName $ComputerName -Credential $creds

## Get cert
$cert = Invoke-Command -Session $session -ScriptBlock {
    Get-ChildItem Cert:\LocalMachine\my | Where-Object {
      ($_.DnsNameList -eq 'DscBastionCert') `
      -and $_.PrivateKey.KeyExchangeAlgorithm `
    }
}

## Extract thumbprint
$thumbprint = $cert.thumbprint

## Optional - show details
Write-Host '//Node Summary' -ForegroundColor Magenta
Write-Host ''
Write-Host $ComputerName -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host ('{0}' -f ($cert | Select-Object -ExpandProperty Subject)) -ForegroundColor Green
Write-Host $thumbprint -ForegroundColor Green

## Summary
<#
This demo showed how to get the required information from
a remote node that has a "bastion" (i.e. not domain-joined)
certificate.
#>

## Next, we review how to handle nodes with the PSDSCPullServerCert:
psedit "C:\DSC_LABS\docs\Demo 20 - Review - How to handle nodes with PSDSCPullServerCert from domain.ps1"