## Example - How to create the second domain controller with dsc

## Introdution
<#
Here, we connect to the existing virtual machine we recently deployed named "dc02".
We promote to a domain controller with typical settings, and join the existing lab.local domain.
This setup requires creating a configuration for both dc01 and dc02.
#>

## Open the configuration script for HADomain. This requires detail about dc01 and dc02.
psedit "C:\DSC_LABS\HADomain.ps1"

## Summary
<#
In this demo, we configured the second domain controller for lab.local.
Deploying a second domain controller is optional, but recommended.
#>

## Next, learn how to create a Certificate Authority (CA) for use with DSC
psedit "C:\DSC_LABS\docs\Demo 14 - How to create a certificate authority (CA) with dsc.ps1"

