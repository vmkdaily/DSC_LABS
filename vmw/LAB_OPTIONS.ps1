## About LAB_OPTIONS.ps1
## This file requires editing / customization for your environment.
## Use this to create variables we can splat to "New-LabVM".

## Instructions
## Make your changes and press the big play button in ISE.
## You will be prompted for the guest login of your Windows template when setting the options.

## Using the options
psedit "C:\DSC_LABS\docs\Demo 3 - How to deploy DSC_LABS with New-LabVM.ps1"

## Edits Required
## Please edit the remainder of the document to suit your environment.

## DNS address for nodes. Pick one variable per node. Each variable can have more than one IP.
$dnsAddress = '10.203.1.40'                  #i.e. 8.8.8.8
$labDNSOnly = '10.205.1.151','10.205.1.152'  #dc01 and dc02
$anotherDnsVariable = ''                     #your own

## Runonce command, if any.
<#
If nothing is specified, the New-LabVM runs a default "RunOnce" to update help and reboot.
If you have a custom script already on your template, point to it here.
This example assumes "c:\ServerBuild\New-WinFwRule.ps1" exists on the template.
#>

$RunOnce = 'powershell.exe C:\ServerBuild\New-WinFwRule.ps1; sleep 5; Restart-Computer -Force'

## Template login
## Here we prompt for guest credential in all cases, unless already loaded.
If(-Not($credsGOS)){
  $credsGOS = Get-Credential -UserName Administrator -Message 'Enter guest os login'
}

## BEGIN CONFIGURATIONS
## CUSTOMIZE EACH NODE BELOW

## Jump
$jump = @{
  Name             = 'dscjump01'
  GuestCredential  = $credsGOS
  MemoryGB         = 8
  NumCPU           = 2
  Description      = 'Jump Server'
  Template         = 'W2016Std-Template-Master'
  IPAddress        = '10.205.1.150'
  SubnetMask       = '255.0.0.0'
  Gateway          = '10.205.1.1'
  DnsAddress       = $dnsAddress
  DnsSuffix        = 'lab.local'
  Folder           = 'DSC LABS'
  PortGroup        = 'VM Network'
  RunOnce          = $RunOnce
  Console          = $true
  Verbose          = $true
}

## dc01
$dc01 = @{
  Name             = 'dc01'
  GuestCredential  = $credsGOS
  MemoryGB         = 8
  NumCPU           = 2
  Description      = 'Domain Controller 1'
  Template         = 'W2012R2Std-Template-Master'
  IPAddress        = '10.205.1.151'
  SubnetMask       = '255.0.0.0'
  Gateway          = '10.205.1.1'
  DnsAddress       = $dnsAddress
  DnsSuffix        = 'lab.local'
  Folder           = 'DSC LABS'
  PortGroup        = 'VM Network'
  RunOnce          = $RunOnce
  Console          = $true
  Verbose          = $true
}

## dc02
$dc02 = @{
  Name             = 'dc02'
  GuestCredential  = $credsGOS
  MemoryGB         = 8
  NumCPU           = 2
  Description      = 'Domain Controller 2'
  Template         = 'W2012R2Std-Template-Master'
  IPAddress        = '10.205.1.152'
  SubnetMask       = '255.0.0.0'
  Gateway          = '10.205.1.1'
  DnsAddress       = $dnsAddress
  DnsSuffix        = 'lab.local'
  Folder           = 'DSC LABS'
  PortGroup        = 'VM Network'
  RunOnce          = ''
  Console          = $true
  Verbose          = $true
}

## cert01
$cert01 = @{
  Name             = 'cert01'
  GuestCredential  = $credsGOS
  MemoryGB         = 4
  NumCPU           = 2
  Description      = 'Certificate Server'
  Template         = 'W2016Std-Template-Master'
  IPAddress        = '10.205.1.153'
  SubnetMask       = '255.0.0.0'
  Gateway          = '10.205.1.1'
  DnsAddress       = $labDNSOnly
  DnsSuffix        = 'lab.local'
  Folder           = 'DSC LABS'
  PortGroup        = 'VM Network'
  RunOnce          = $RunOnce
  Console          = $true
}

## dscpull01
$dscpull01 = @{
  Name             = 'dscpull01'
  GuestCredential  = $credsGOS
  MemoryGB         = 4
  NumCPU           = 2
  Description      = 'Pull Server'
  Template         = 'W2016Std-Template-Master'
  IPAddress        = '10.205.1.154'
  SubnetMask       = '255.0.0.0'
  Gateway          = '10.205.1.1'
  DnsAddress       = $labDNSOnly
  DnsSuffix        = 'lab.local'
  Folder           = 'DSC LABS'
  PortGroup        = 'VM Network'
  RunOnce          = $RunOnce
}

## s1
$s1 = @{
  Name             = 's1'
  GuestCredential  = $credsGOS
  MemoryGB         = 4
  NumCPU           = 2
  Description      = 'Test Node 1'
  Template         = 'W2012R2Std-Template-Master'
  IPAddress        = '10.205.1.155'
  SubnetMask       = '255.0.0.0'
  Gateway          = '10.205.1.1'
  DnsAddress       = $labDNSOnly
  DnsSuffix        = 'lab.local'
  Folder           = 'DSC LABS'
  PortGroup        = 'VM Network'
  RunOnce          = $RunOnce
  Console          = $true
}

## s2
$s2 = @{
  Name             = 's2'
  GuestCredential  = $credsGOS
  MemoryGB         = 4
  NumCPU           = 2
  Description      = 'Test Node 2'
  Template         = 'W2016Std-Template-Master'
  IPAddress        = '10.205.1.156'
  SubnetMask       = '255.0.0.0'
  Gateway          = '10.205.1.1'
  DnsAddress       = $labDNSOnly
  DnsSuffix        = 'lab.local'
  Folder           = 'DSC LABS'
  PortGroup        = 'VM Network'
  RunOnce          = $RunOnce
  Console          = $true
}

## END OF CONFIGURATIONS

#############
## APPENDIX
#############

<#

    ###################################
    ## How to use "New-LabVM"
    ###################################
    The LAB_OPTIONS.ps1 file only uses a portion of the available parameters of New-LabVM.
    Check them all out with "help New-LabVM -Syntax".

    Import-Module C:\DSC_LABS\vmw\New-LabVM.ps1
    $credsVC = Get-Credential administrator@vsphere.local
    $vc = '10.205.1.37'
    Connect-VIServer -Server $vc -Credential $credsVC

    ## OVERVIEW
    Step 1. Open the LAB_OPTIONS.ps1 in the Microsoft ISE.
    Step 2. Customize as desired.
    Step 3. Press the big play button in ISE to load the options.
    Step 4. You will be prompted for guest login.
    Step 5. The options are now loaded; Confirm by reviewing variables such as $jump, $s1, $s2, etc.
    
    ## Edit and import the options
    psedit "C:\DSC\LABS\vmw\LAB_OPTIONS.ps1"
    
    ## show s1 options
    $s1

    ## deploy s1 with splatting
    ## To use the $s1 options, we pass it as @s1.
    New-LabVM @s1

    ## Disconnect from vc
    Disconnect-VIServer

#>