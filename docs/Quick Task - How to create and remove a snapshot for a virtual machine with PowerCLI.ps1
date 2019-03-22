## How to create and remove a snapshot for a virtual machine with PowerCLI

## Connect to vc
$credsVC = Get-Credential administrator@vsphere.local
$vc = '10.205.1.37'
Connect-VIServer -Server $vc -Credential $credsVC

## Show connection
Clear-Host
$Global:DefaultVIServers

## Get virtual machine object
$vm = Get-VM 'dscjump01' -Server $vc

## Show existing snapshots
Get-Snapshot -VM $vm

## Create a new snapshot 
New-Snapshot -VM $vm -Name 'snap 1' -Description ('Snapshot for {0}' -f $vm.Name) -Memory:$true

## Remove a snapshot
Get-Snapshot -VM $vm -Name 'snap 1' | Remove-Snapshot -Confirm:$false

## Disconnect from vc
Disconnect-VIServer -Server $vc -Confirm:$false