## How to create a certificate authority (CA) with dsc

## Introduction
<#
Here, we connect to the existing virtual machine we recently deployed named "cert01".
We install all required components to make it a CA for lab.local.
#>

## Create self-signed cert
psedit "C:\DSC_LABS\docs\Demo 10 - Prepare a Server 2016 Bastion host for DSC.ps1"
psedit "C:\DSC_LABS\docs\Demo 11 - Prepare a Server 2012 R2 Bastion host for DSC.ps1"

## Configuration for "cert01"
## Open the configuration script for the second domain controller:
psedit "C:\DSC_LABS\NewCertServer.ps1"

## Summary
<#
In this demo, we configured the cert01 server to be a CA for lab.local.
In the coming demos, we will configure certificates for the domain,
the pull server (IIS), and the compliance server feature of our pull server.
#>

## Next, we discuss the manual steps required to create certificates and GPOs.
psedit "C:\DSC_LABS\docs\Demo 15 - How to run manual steps for certificate and GPO setup.ps1"

## Or, skip ahead to configuring the pull server with dsc
psedit "C:\DSC_LABS\docs\Demo 16 - How to create a dsc pull server with dsc.ps1"


