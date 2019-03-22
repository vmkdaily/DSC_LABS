## How to run a script on a remote Guest with PowerCLI

## Connect to VC, if needed.
$vc = '10.205.1.11'
$credsVC = Get-Credential administrator@vsphere.local
Connect-VIServer $vc -Credential $credsVC

## Confirm you are connected
$global:DefaultVIServer

## Prepare variables
$error.Clear();clear
$DisplayName = 'dc01'
$guestIP = '10.205.1.151'
$GuestUser = 'Administrator'
$GuestPassword = (Get-Credential $guestIP\Administrator).Password

## Script to run. The script must be on guest already.
$ScriptPath = "C:\ServerBuild\New-WinFwRule.ps1"

Invoke-VMScript -VM $DisplayName `
-GuestUser $GuestUser `
-GuestPassword $GuestPassword `
-ScriptText $ScriptPath `
-ScriptType PowerShell `
-Verbose:$true

## Or, command to run.
$ScriptText = "winrm quickconfig"

Invoke-VMScript -VM $DisplayName `
-GuestUser $GuestUser `
-GuestPassword $GuestPassword `
-ScriptText $ScriptText `
-ScriptType PowerShell `
-Verbose:$true

## Disconnect VIServer
Disconnect-VIServer $vc -Confirm:$false

## Note: Now that the firewall is under our control, we can use WinRM and similar.

## Summary
<#
This demo executed a script on a new virtual machine using
native VMware PowerCLI cmdlets. This prepares the remote
node for WinRM. We still have some work on our local client though.
#>

## Next, we configure our client for WinRM communication to remote nodes.
psedit "C:\DSC_LABS\docs\Demo 6 - How to handle WinRM trusted hosts.ps1"