#How to shutdown and delete virtual machines in DSC LABS

## Login to vc
$credsVC = Get-Credential administrator@vsphere.local
Connect-VIServer -Server '10.205.1.37' -Credential $credsVC

## Get VM List
$list = Get-VM -Location (Get-Folder "DSC LABS")

## Show VMs
$list

## Leaving lab.local
<#
To prepare for shutdown and removal of all lab nodes,
remove your jump server from the lab.local domain first.

Simply run the "sysdm.cpl" command and click "Change" to enter a workgroup.
Note: Must know the guest local Administrator password after leaving domain.
#>
    #Enter a workgroup
    #From start > run or any shell:
    sysdm.cpl

## Shutdown VMs
[bool]$ConfirmShutDownPreference = $false
$list | % { Shutdown-VMGuest $_ -Confirm:$ConfirmShutDownPreference -ErrorAction Ignore }

## Remove VMs
[bool]$ConfirmDeletePreference = $true
$list | % { Remove-VM $_ -DeletePermanently -Confirm:$ConfirmDeletePreference }

## Login to jump server
## After leaving the domain, your PowerShell $profile (if any)
## will be that of the local Administrator. To see the path to your
## $profile you can output to Format-List. You may want to psedit "some path"
## to copy some contents of a profile.

    #show profile path
    $profile | fl *

    #example output
    C:\Users\Administrator\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1

## Show all profiles for this user (includes console and ise)
    
    gci C:\Users\Administrator\Documents\WindowsPowerShell\

## show ALL USERS and all profiles

    gci C:\Users\*\Documents\WindowsPowerShell\

## Show only the ISE profile for all users.

    gci C:\Users\*\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1

## For more detail on configuring your jump or authoring machine, see:
psedit "C:\DSC_LABS\docs\Demo 1 - How to prepare your client or authoring machine.ps1"

