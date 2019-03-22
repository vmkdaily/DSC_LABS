# How to create a new virtual machine to run ESXi nested

## Introduction
## In this demo we deploy a virtual machine using the vSphere API.
## We then configure settings to create a nested ESXi host.
## Alternatively, one can use New-VM instead.

## Import the PowerCLI module
Import-Module VMware.PowerCLI

## Connect to vCenter
$vc = '10.205.1.37'
$credsVC = Get-Credential administrator@vsphere.local
Connect-VIServer $vc -Credential $credsVC

## Connect to VC API
Connect-CisServer $global:DefaultVIServer -Credential $credsVC

## Show connections
Clear-Host
Write-Host '//vCenter Connection:' -ForegroundColor Magenta
$global:DefaultVIServer
Write-Host ''
Write-Host '//VC API connection:' -ForegroundColor Magenta
If($global:DefaultCisServers.IsConnected){
    $global:DefaultCisServers
}
Else{
    Write-Warning -Message 'VC API connection timed out or not active!'
}

## view example
help Get-CisService -Examples

#################
## Build options
#################
    
# Get the service for VM management 
$vmService = Get-CisService "com.vmware.vcenter.VM"
    
# Create a VM creation specification 
$createSpec = $vmService.Help.create.spec.Create()

# Fill in the creation details
$createSpec.name = "esx01"
$createSpec.guest_OS = "VMKERNEL_65"  #i.e. VMKERNEL_60 or VMKERNEL_65, max is the version of VIServer API you will deploy onto.
   
# Create a placement specification
$createSpec.placement = $vmService.Help.create.spec.placement.Create()
    
# Fill in the placement details
$createSpec.placement.folder = (Get-Folder vm).ExtensionData.MoRef.Value
$createSpec.placement.host = (Get-VMHost)[0].ExtensionData.MoRef.Value
$createSpec.placement.datastore = (Get-Datastore)[0].ExtensionData.MoRef.Value
    
# Create the virtual machine by calling the create method passing the specification. Creates a minimal guest with 1 cpu and 2GB memory by default.
$vmService.create( $createSpec )


<#
Note: The above Connects to a vSphere Automation SDK server,
retrieves the service for virtual machine management,
and  creates a virtual machine, based on the provided 
creation details by passing the specification to the
create method.
#>

## Troubleshooting
<#
 If too much time has passed since creating your API connection,
 you may need to perform session cleanup at the end of this document
 and then go back to the top of the document to connect again.
#>

## Get and show the VM object
$vm = Get-VM -Name 'esx01';$vm

## Set the size of nested ESXi virtual machine (REQUIRES RESOURCES!)
$numCPU = 16  #minimum 2
$MemoryGB = 64 #minimum 4; 6 to 8+ preferred to run guests
Set-VM -VM $vm -NumCpu $numCPU -MemoryGB $MemoryGB -Notes "Nested ESXi for DSC Labs" -Verbose

## show updated vm detail
$vm = Get-VM -Name "esx01"; Clear-Host; $vm

## Additional detail:
Clear-Host
Write-Host ''
Write-Host '//VM detail:' -ForegroundColor Magenta
$vm.Name
$vm.GuestId
$vm.ExtensionData.Config.GuestFullName

## Optional - delete the vm
Get-VM -Name 'esx01' | Remove-VM -DeletePermanently -Confirm:$true

## copy iso to datastore
## manual step or use the VIStore

## get vm object
$vm = Get-VM -Name 'esx01';$vm
Start-Sleep 3

## check if we can handle creating the desired BIG vmdk
Clear-Host
$dsObj = Get-Datastore 'datastore2-raid5'
$SizeOfDiskToAdd = 600  #set your desired size here
$dsSize = $dsObj.CapacityGB
$dsFreeSpaceGB = $dsObj.FreeSpaceGB
$dsMaxUsageAllowed = .80
$Threshold = $dsSize - ($dsSize * $dsMaxUsageAllowed)
$predictedFree = $dsFreeSpaceGB - $SizeOfDiskToAdd

If($predictedFree -lt $Threshold){
    [bool]$permitDiskAdd = $false
    throw 'Not enough room!'
}
Else{
    Write-Host ('Looking good on datastore {0}!' -f $dsObj.Name) -ForegroundColor Green -BackgroundColor DarkGreen
    ('FreeSpace is currently {0}' -f $dsFreeSpaceGB)
    ('Predicted free is {0} (after diskadd)' -f $predictedFree)
    [bool]$permitDiskAdd = $true
    Start-Sleep -Seconds 5
}

## Params for hard drive addition
$params = @{
    VM = $vm
    Datastore = $dsObj
    CapacityGB = $SizeOfDiskToAdd
    ThinProvisioned = $true
}

## show params
$params
Start-Sleep 5

## add the disk splatting in the @params
Clear-Host
If($true -eq $permitDiskAdd){
    New-HardDisk @params
}
Else{
    Write-Warning -Message 'Disk add operation denied!'
}

## Set CDROM to boot to the ESXI ISO (requires iso on datastore)
$existsCDDrive = Get-CDDrive -VM $vm -ErrorAction Ignore
If(-Not($existsCDDrive)){
    $null = New-CDDrive -VM $vm -Confirm:$false
}
$dsIsoPath = '[datastore2-raid5] ISO/esx01.iso'
$CDDrive = Get-CDDrive -VM $vm
Set-CDDrive -CD $CDDrive -IsoPath $dsIsoPath -StartConnected:$true

## show updated cd detail
Get-CDDrive -VM $vm | fl *

## Add two vNIC adapters
1..2 | % { New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName 'VM Network' -StartConnected:$true }

## MANUAL STEP - New advanced setting for vm (enable hardware virtualization)
## Navigate to:

    "web client > edit settings > cpu > enable hw virt"

## Power ON VM
Start-VM -VM $vm; Start-Sleep 5; Set-CDDrive -CD $CDDrive -StartConnected:$false

## Optional - Open console
Open-VMConsoleWindow -VM $vm

## Session cleanup
$null = Disconnect-VIServer * -Confirm:$false -ErrorAction Ignore
$null = Disconnect-CisServer * -Confirm:$false -ErrorAction Ignore

## Summary
## In this demo we created a new virtual machine to run nested ESXi.

## Next, perform Post steps on the new ESXi host:
psedit "C:\DSC_LABS\vmw\advanced\Part 3 - Performing ESXi Post steps for nested ESXi.ps1"


## APPENDIX - How to macfilter for nested ESXi.

## MANUAL STEP
## Optional - Choose a mac learning kit (unless on latest 6.7 where it is native).
https://labs.vmware.com/flings/esxi-mac-learning-dvfilter#instructions
https://labs.vmware.com/flings/learnswitch

<#
Note: "Learnswitch" is the latest, but requires a reboot of your parent ESXi host (the outter hypervisor).
The "esxi-mac-learning-dvfilter" is older, but does not require a reboot.

LearnSwitch                  esxi-mac-learning-dvfilter
____________                 ___________________________
Reboot required              No reboot
VDS required                 Supports vStandard Switch (vSS) or VDS
clear mac table (5 mins)     clear mac table (never)*

#>

#Note: The examples below use "esxi-mac-learning-dvfilter"

## Pre-step - install the appropriate vib for 60 or 6.5 (6.7 latest not needed).
## Follow fling instructions.
## When the vib is installed proceed.

## Connect to vc
Connect-VIServer "yourvcenter" -Credential (Get-Credential administrator@vsphere.local)
$vm = Get-VM -Name 'esx01'

## Get current settings; We compare counts later.
$PreMaint = Get-AdvancedSetting -Entity $vm

## Add advanced settings
## To use the "esxi-mac-learning-dvfilter" fling, we need to add two entries per vNIC.
New-AdvancedSetting -Entity $vm -Name 'ethernet0.filter4.name' -Value 'dvfilter-maclearn'
New-AdvancedSetting -Entity $vm -Name 'ethernet0.filter4.onFailure' -Value 'failOpen'
New-AdvancedSetting -Entity $vm -Name 'ethernet1.filter4.name' -Value 'dvfilter-maclearn'
New-AdvancedSetting -Entity $vm -Name 'ethernet1.filter4.onFailure' -Value 'failOpen'

## ssh to ESXi and hot-reload the vm
<#

## get all VMs
vim-cmd vmsvc/getallvms

## use the id of desired vm
vim-cmd vmsvc/reload 147

## show the settings in action
/sbin/summarize-dvfilter

#>

## get the post-maintenance count
$latest = Get-AdvancedSetting -Entity $vm

## show pre-maint
$initial.Count
48

## show post maint
$latest.Count
52

## look at just one setting
Get-AdvancedSetting -Entity $vm -Name 'ethernet0.filter4.name'

## session cleanup
$null = Disconnect-VIServer * -Confirm:$false -ErrorAction Ignore