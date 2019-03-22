## Example - How to create a domain controller and domain with dsc

## Introduction
<#
Here, we connect to the existing virtual machine we recently deployed named "dc01".
We promote to a domain controller with typical settings, and create a domain
named lab.local
#>

## Configuration for "DC01"
## Open the configuration script for the first domain controller:
psedit "C:\DSC_LABS\NewDomain.ps1"

## Or, use the "HADomain.ps1" configuration to handle both domain controllers at once (dc01 and dc02).
psedit "C:\DSC_LABS\HADomain.ps1"

## Summary
<#
 In this demo, we promoted the "dc01" node into a domain controller.
 This also created the lab.local domain and a DNS server we can use internally now.
#>

## Next, we add the second domain controller
psedit "C:\DSC_LABS\docs\Demo 13 - How to create the second domain controller with dsc.ps1"

## Or, skip ahead and create the Certificate Authority (CA) with dsc
psedit "C:\DSC_LABS\docs\Demo 14 - How to create a certificate authority (CA) with dsc.ps1"