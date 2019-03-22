## How to run ESXi Post steps for nested ESXi

## Connect to ESXi
$esxName = 'esx01.lab.local'
Connect-VIServer $esxName -Credential (Get-Credential root)

## Add secondary NIC
Get-VirtualPortGroup -Name "Management Network" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic1

## Configure NTP
$ntpServer = '10.1.2.3' #adjust as needed
$esxName = 'esx01.lab.local'
$esxImpl = Get-VMHost $esxName

## Get current ntp settings, if any
$ntpStatus = Get-VMHost | Select-Object name, @{N="NTPServer";E={$_ |Get-VMHostNtpServer}}, @{N="ServiceRunning";E={(Get-VmHostService -VMHost $_ | Where-Object {$_.key -like 'ntpd'}).Running}} -ErrorAction SilentlyContinue
            
## Skip if already configured
If($ntpStatus.NTPServer -match $ntpServer){
    Write-Verbose -Message ('Skipping NTP configuration for host {0} which is already using {1}' -f $esxName, $ntpServer)
}
Else{
    # Configure and enable NTP
    Write-Verbose -Message "Configuring NTP Settings"
    Add-VmHostNtpServer -NtpServer $ntpServer -VMHost $esxImpl -Confirm:$false
    $ntpd = Get-VMHostService | Where-Object {$_.key -eq 'ntpd'}
    Set-VMHostService $ntpd -Policy Automatic -Confirm:$false
    Restart-VMHostService $ntpd -Confirm:$false
}

## Configure storage
$esxName = 'esx01.lab.local'
$esxImpl = Get-VMHost $esxName
$dsList = Get-SCSILun -LunType disk
$dsPath = $dsList | Sort-Object CapacityGB -Descending  |Select-Object -First 1 -ExpandProperty CanonicalName
New-Datastore -VMHost $esxImpl -Name datastore2 -Path $dsPath -Vmfs -FileSystemVersion 6

## Session cleanup
$null = Disconnect-VIServer * -Confirm:$false -ErrorAction Ignore

## Summary
## In this demo, we performed Post steps on our nested ESXi host.
## Now you are ready to run some guests.

## Next, learn how to deploy a fully configured vCenter Appliance:
psedit "C:\DSC_LABS\vmw\advanced\Part 4 - Deploying vcsa with Invoke-OvfTool.ps1"


