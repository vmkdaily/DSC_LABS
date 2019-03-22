#Requires -Version 3

<#
    .DESCRIPTION
      Create Windows firewall rules to allow basic communication.
      Also enables WinRM and clears the Windows Event Logs.
      This should be run directly on a newly deployed Windows guest.

    .NOTES
      Script:   New-WinFwRule.ps1
      Author:   Mike Nisk
#>

[CmdletBinding()]
Param()

Process {

  ## Enable ICMP, etc.
  Write-Host 'Enable ICMP: ' -NoNewline
  try{
    $null = Set-NetFirewallRule -DisplayGroup 'File And Printer Sharing' -Enabled True -Profile Any -Confirm:$False -ErrorAction Stop
    Write-Host 'Success' -ForegroundColor Green -BackgroundColor DarkGreen
  }
  catch{
    Write-Host 'Failed' -ForegroundColor Red -BackgroundColor DarkRed
    Write-Error -Message $Error[0].exception.Message
  }
  
  ## Get PowerShell Remoting Rules
  try{
    $wrmRules = Get-NetFireWallRule -ErrorAction Stop | Where-Object {$_.Name -match '^WinRM'}
  }
  catch{
    Write-Error -Message $Error[0].exception.Message
  }
  
  ## Set PowerShell Remoting Rules
  Write-Host 'Enable WinRM: ' -NoNewline
  try{
    $null = $wrmRules | Set-NetFirewallRule -Enabled True -Profile Any -ErrorAction Stop -Confirm:$False
    Write-Host 'Success' -ForegroundColor Green -BackgroundColor DarkGreen
  }
  catch{
    Write-Host 'Failed' -ForegroundColor Red -BackgroundColor DarkRed
    Write-Error -Message $Error[0].exception.Message
  }
  
  ## Enable RDP in the Windows registry
  Write-Host 'Enable RDP in Registry: ' -NoNewline
  try{
    $null = Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name 'fDenyTSConnections' -Value 0 -Confirm:$false -ErrorAction Stop 
    Write-Host 'Success' -ForegroundColor Green -BackgroundColor DarkGreen
  }
  catch{
    Write-Host 'Failed' -ForegroundColor Red -BackgroundColor DarkRed
    Write-Warning -Message 'Problem enabling RDP!'
    Write-Error -Message $Error[0].exception.Message
  }
  
  ## Enable RDP FW Rule
  Write-Host 'Enable RDP FW Rule:' -NoNewline
  try{
    $null = Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -Confirm:$False -ErrorAction Stop
    Write-Host 'Success' -ForegroundColor Green -BackgroundColor DarkGreen
  }
  catch{
    Write-Host 'Failed' -ForegroundColor Red -BackgroundColor DarkRed
    Write-Warning -Message 'Problem enabling RDP Firewall rule!'
    Write-Error -Message $Error[0].exception.Message
  }
  
  ## Get w32Time service info
  $timeSvc = Get-Service -Name W32Time
  $timeSvcStartType = $timeSvc | Select-Object -ExpandProperty StartType

  ## Sets the StartType for the service w32 service. More handling is done in post.
  If($timeSvcStartType -match '^Disabled'){
    try{
      $null = $timeSvc | Set-Service -StartupType 'Manual' -Confirm:$false -ErrorAction Stop
    }
    catch{
      Write-Warning -Message 'Problem setting w32Time service to Manual start!'
      Write-Error -Message $Error[0].exception.Message
    }
  }
  
  ## Clear Windows event logs
  Write-Host 'Clear Windows Event Logs: ' -NoNewline
  try{
    $null = Clear-EventLog -LogName System,Application,Security -Confirm:$false -ErrorAction Stop
    Write-Host 'Success' -ForegroundColor Green -BackgroundColor DarkGreen
  }
  catch{
    Write-Host 'Failed' -ForegroundColor Red -BackgroundColor DarkRed
    Write-Warning -Message 'Problem clearing event log!'
  }
  
  Write-Host 'Done processing!'
  Write-Host ''
}