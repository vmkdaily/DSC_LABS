## Example - How to run manual steps for certificate and GPO setup

## Introduction
## There are some manual steps for certificate and GPO creation. Perform each of these, in order:

## Create certificate on CA
psedit "C:\DSC_LABS\docs\Manual Steps - Create a DSC Certificate on a CA.ps1"

## Link the GPO so all domain members get the cert
psedit "C:\DSC_LABS\docs\Manual Steps - Create and Link a GPO for Domain Members to Consume the DscCert.ps1"

## Create a certificate for the dsc web service (and optionally compliance)
psedit "C:\DSC_LABS\docs\Manual Steps - Create a Certificate for the Dsc Web Server.ps1"

## Summary
<#
In this demo, we created a CA-signed certificate in the lab.local domain.
We also created a GPO and linked our cert to the domain so all machines get this cert.
Finally, we prepared certificates for the dsc pull server (web and compliance).
#>

## Next, we build out the dsc pull server with dsc:
psedit "C:\DSC_LABS\docs\Demo 16 - How to create a dsc pull server with dsc.ps1"


