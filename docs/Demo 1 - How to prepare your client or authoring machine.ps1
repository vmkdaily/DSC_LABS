## How to prepare your client or authoring machine

<#

## Introduction
Welcome to DSC_LABS.

In this Demo 1, we get your jump box setup.
This is the first of many demos to get us up and running with Desired State Configuration (DSC).
Optionally, also see the Appendix at the end of this demo for the full "Authoring" machine setup.

## About jump server
In the Demos, we deploy a virtual machine with a Name of "dscjump01" and an
IP Address of "10.205.1.150". You can also provide your own jump server if desired.

## Starter Path
Note that some users will only do Demos 1 to 3, which is enough to deploy a VM.
That VM could be a jump server, then you would come back and do Demos 1 - 3 for it.
Finally, you would proceed through all Demos to complete the jump server build.

## About the Bits, DSC_LABS.zip
In all cases, we need to have access to the DSC_LABS folder.
This contains docs, configurations, and scripts we will need later.

#>

## Step 1. Copy and Uncompress (manual)
<#
Copy the DSC_LABS.zip to your desktop or downloads.
Optionally, right-click the zip and select Properties, and then unblock.
By unblocking a zip, we have the benefit of all sub-files being unblocked too.
Next, uncompress the zip and copy it to the C:\ drive.
The result on your client or jump server should look like the following:
#>

  c:\DSC_LABS

## Confirm Path

  Test-Path "C:\DSC_LABS"

## Summary
<#

In this demo, we performed the basic step of placing the DSC_LABS folder
on the C:\ drive of your client or jump server.

#>

## In the next demo,we handle PowerCLI configuration with "Set-PowerCLIConfiguration".
psedit "C:\DSC_LABS\docs\Demo 2 - How to Setup PowerCLI.ps1"


## Note: For more authoring tools setup, proceed to the Appendix.

###############################
## APPENDIX - AUTHORING SETUP
###############################

## Step I. RDP to the jump server.

  mstsc /v:10.205.1.150

## Step II. Launch ISE as Administrator (UAC)

## Step III. Optional - Create ISE $profile
If(-Not(Test-Path $profile)){
    New-Item -ItemType File -Path $profile -Force
    psedit $profile
}
Else{
    Get-Content $profile
}

## Show module locations
$env:PSModulePath -split ';'


## List installed modules
gci "C:\Program Files\WindowsPowerShell\Modules" | ?{$_.Name -notmatch '^VMware'}

## Step IV. Install modules on your jump server or client
Install-Module -Name xActiveDirectory
Install-Module -Name xComputerManagement
Install-Module -Name xDnsServer
Install-Module -Name xNetworking
Install-Module -Name xTimeZone
Install-Module -Name xPSDesiredStateConfiguration
Install-Module -Name xAdcsDeployment
Install-Module -Name ComputerManagementDsc

## Optional - Update PackageManagement

    Install-Module PackageManagement

## Optional - Configure PSGallery access via proxy server:

    psedit "C:\DSC_LABS\docs\Quick Task - How to configure remote node proxy server for PSGallery (optional).ps1"

## Step V. Optional - Install the PSPKI module now. We do this in a later demo as well.

    Install-Module -Name PSPKI


## Next, we handle PowerCLI configuration with "Set-PowerCLIConfiguration"

    psedit "C:\DSC_LABS\docs\Demo 2 - How to Setup PowerCLI.ps1"
