## How to deploy vcsa with Invoke-OvfTool.

## Supports deploying to ESXi directly, or to an existing vCenter.

## Optional - Import the PowerCLI module
Import-Module VMware.PowerCLI

## Import module
Remove-Module Invoke-OvfTool -ea Ignore
Import-Module C:\DSC_LABS\vmw\advanced\Invoke-OvfTool.ps1 -Verbose

## get help
help Invoke-OvfTool -Examples

## Ovf Configuration
$OvfConfig = @{
      esxHostName            = "esx01.lab.local"
      esxUserName            = "root"
      esxPassword            = "VMware123!!"
      esxPortGroup           = "VM Network"
      esxDatastore           = "datastore2"
      ThinProvisioned        = $true
      DeploymentSize         = "tiny"
      DisplayName            = "vcsa01"
      IpFamily               = "ipv4"
      IpMode                 = "static"
      Ip                     = "10.205.1.11"
      FQDN                   = "10.205.1.11"
      Dns                    = @("10.203.1.40","10.205.1.151") #max of 2
      SubnetLength           = "8"
      Gateway                = "10.205.1.1"
      VcRootPassword         = "VMware123!!"
      VcNtp                  = "10.205.1.9"
      SshEnabled             = $true
      ssoPassword            = "VMware123!!"
      ssoDomainName          = "vsphere.local"
      ceipEnabled            = $false
}

## Show options
$OvfConfig

## Disconnect existing sessions
If($Global:DefaultVIServers){
    $Global:DefaultVIServers | % { Disconnect-VIServer $_ -Confirm:$false -ErrorAction Ignore }
}

## About connecting
<#
 We can use vCenter or an ESXi host without a VC.
 This is because the ovftool that we use can handle both.
 For this case, we will just refer to it as "VIServer".
 Next, we get connected, etc.
#>

## ESXi host or VC Name
$VIServer = 'esx01.lab.local'

## Optional - ping the desired VIServer.
Test-Connection $VIServer -Count 1

## Connect to VIServer
$creds = Get-Credential
Connect-VIServer $VIServer -Credential $creds

## Create the JSON file. This combines the default VMware provided detail from their 'template', along with your options on top.
$Json = Invoke-OvfTool -OvfConfig $OvfConfig -Mode Design

## Show path to JSON file. Use the path in the next command.
$Json  | fl *

## example output
<#
    PS C:\> $Json  | fl *
    True
    C:\Users\Administrator\AppData\Local\Temp\myConfig.JSON
#>

## Set your path, using output from above. The path will be the same every time for the user running it.
$path = "TODO" #enter your path

## Break Time
## The next step takes ~1 hour. Run the command and come back later.

## Deploy VC Appliance
Invoke-OvfTool -OvfConfig $OvfConfig -Mode Deploy -JsonPath $path -Verbose

## Show all logs
Invoke-OvfTool -Mode LogView

## Show specific log detail
Invoke-OvfTool -Mode LogView -Path C:\Users\ADMINI~1\AppData\Local\Temp\workflow_1551300864408 | fl *

## session cleanup
Disconnect-VIServer * -Confirm:$false

## Summary
## In this demo we deployed a fully customized vCenter Server appliance.
## This completes the advanced demos. Next, you can work on replacing these
## manual PowerCLI techniques with DSC.