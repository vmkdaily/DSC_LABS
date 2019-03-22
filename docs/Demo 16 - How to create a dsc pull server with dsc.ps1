## Example - How to create a dsc pull server with dsc

<#

## Introduction
Here, we connect to the existing virtual machine we recently deployed named "dscpull01".
We then install all required software to turn this server into a dsc pull server.

## Prerequisites
- Must have already configured CA certs
- Must have already copied required resources to remote node with Copy-Item or similar.

## Example required modules:
PSDesiredStateConfiguration,xPSDesiredStateConfiguration,xTimeZone,ComputerManagementDsc,NetworkingDsc

#>

## Perform "Manual Steps" for certificate setup if you have not done that yet.
psedit "C:\DSC_LABS\docs\Manual Steps - Create a Certificate for the Dsc Web Server.ps1"
psedit "C:\DSC_LABS\docs\Manual Steps - Create a DSC Certificate on a CA.ps1"
psedit "C:\DSC_LABS\docs\Manual Steps - Create and Link a GPO for Domain Members to Consume the DscCert.ps1"

## Optional - Domain join to lab.local now, or let the main config handle it.
psedit "C:\DSC_LABS\JoinLabDomain.ps1"

## Optional - Configure IP now, or let the main config handle it.
psedit "C:\DSC_LABS\SetNodeIPAddress.ps1"

## Configuration for "dscpull01"
## Open the configuration script
psedit "C:\DSC_LABS\NewPullServer.ps1"

## Summary
<#
In this demo, we configured the dsc pull server using dsc.
Now, we can start using the pull server to manage the configurations.
#>

## Next, we manage our first test node named "s1".
psedit "C:\DSC_LABS\docs\Demo 17 - How to deploy first test node (s1).ps1"


