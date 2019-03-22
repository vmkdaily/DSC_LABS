## How to Copy a file with PowerCLI (Client to Guest)

## Disconnect from any existing servers. if needed
If($Global:DefaultVIServer){
  $null = Disconnect-VIServer * -Confirm:$false -ErrorAction Ignore
}

## Connect to VC
$vc = '10.205.1.11'
$credsVC = Get-Credential administrator@vsphere.local
Connect-VIServer $vc -Credential $credsVC

## Confirm you are connected
Clear-Host
$global:DefaultVIServer

## Prepare variables
$error.Clear();clear
$DisplayName = 'dc01'
$guestIP = '10.205.1.151'
$GuestUser = 'Administrator'
$GuestPassword = (Get-Credential $guestIP\Administrator).Password
$source = "C:\DSC_LABS\dsc-payload\New-WinFwRule.ps1"
$destination = "C:\ServerBuild\"  #this will be created if needed. Or, use "C:\Windows\Temp"

## Confirm access to source
Test-Path $source

## Copy to guest
Copy-VMGuestFile -VM $DisplayName `
-Server $vc `
-LocalToGuest:$true `
-Source $Source `
-Destination $Destination `
-GuestUser $GuestUser `
-GuestPassword $GuestPassword `
-Force:$true `
-Confirm:$false `
-Verbose:$true

## Optionally, disconnect VIServer (or move on to next step, running the script)
Disconnect-VIServer $vc -Confirm:$false

## Next, see how to run the script:
psedit "C:\DSC_LABS\docs\Demo 5 - How to run a script on a remote Guest with PowerCLI.ps1"