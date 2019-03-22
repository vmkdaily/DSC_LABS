## How to execute commands on remote sessions with native PowerShell Remoting (WinRM)

## Note: If you need a refresher, see:
psedit "C:\DSC_LABS\docs\Demo 6 - How to handle WinRM trusted hosts.ps1"

$ComputerName = '10.205.1.151'
$nodeCreds = Get-Credential ('{0}\Administrator' -f $ComputerName)
$session = New-PSSession -ComputerName $ComputerName -Credential $nodeCreds

## Example - Running some code remotely
Invoke-Command -Session $session -ScriptBlock {
  ## some code here
  cat env:ComputerName
  
  ## More code here
  Update-Help -Verbose -ErrorAction Ignore
}

## Next, we configure a Windows Server 2016 guest:
psedit "C:\DSC_LABS\docs\Demo 10 - Prepare a Server 2016 Bastion host for DSC.ps1"

## Or, skip ahead to Windows Server 2012 R2
psedit "C:\DSC_LABS\docs\Demo 11 - Prepare a Server 2012 R2 Bastion host for DSC.ps1"