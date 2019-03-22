## How to deploy DSC_LABS with New-LabVM

<#

## Introduction
The New-LabVM function depends on LAB_OPTIONS.ps1, which contains names and IP Addresses, etc.

Here we run the New-LabVM PowerCLI function to create one or more virtual machines with PowerCLI.

## Server types we can deploy
Jump server, domain controllers, certificate server, pull server, and/or Windows test nodes.

#>

## Import the PowerCLI module into ISE
Import-Module -Name VMware.PowerCLI

## Login to vc
$vc = '10.205.1.11'
$credsVC = Get-Credential administrator@vsphere.local
Connect-VIServer $vc -Credential $credsVC

## Show vc connection
Clear-Host
$Global:DefaultVIServers

#Import the New-LabVM function, if needed
If(-Not(gcm New-LabVM -ea Ignore)){
  Import-Module C:\DSC_LABS\vmw\New-LabVM.ps1 -Verbose
}

## Edit the LAB_OPTIONS
psedit "C:\DSC_LABS\vmw\LAB_OPTIONS.ps1"

## Import the LAB_OPTIONS if needed
Import-Module "C:\DSC\LABS\vmw\LAB_OPTIONS.ps1"

## Show options for dc01
$dc01

## Deploy with splatting
New-LabVM @dc01

## Other VMs
## Repeat for all desired servers to deploy.

    #Deploy second DC
    New-LabVM @dc02

    #Deploy cert01
    New-LabVM @cert01

    #Deploy dscpull01
    New-LabVM @dscpull01

## Deploy Test VMs
## Optionally, deploy test VMs now. We do this in later demos in detail.

    ## Deploy first test vm
    New-LabVM @s1

    ## Deploy second test vm
    New-LabVM @s2

## Disconnect from vc
Disconnect-VIServer -confirm:$false
    
## Summary
## In this demo, we deployed one or more virtual machines for use with DSC_LABS.
## The deployed guests will have IP Address assigned, but will not be in the domain.

## Note: Unless you provided a "RunOnce" to handle your guest firewall, you may not be able to reach it.
## In the next demo, we learn how to get a script to a guest, even without networking or when locked down by firewall. 

## Next, see how to copy a file to a guest with native VMware PowerCLI cmdlets.
psedit "C:\DSC_LABS\docs\Demo 4 - How to Copy a file with PowerCLI (Client to Guest).ps1"
