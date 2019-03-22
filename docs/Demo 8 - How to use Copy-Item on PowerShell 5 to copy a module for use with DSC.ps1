## How to use Copy-Item on PowerShell 5 to copy a module for use with DSC

## Introduction
## This demo shows how to copy files to a remote node using PowerShell Copy-Item.

## Runtime session setup
$ComputerName = '10.205.1.151' #Name or IP Address of remote node.
$nodeCreds = Get-Credential ('{0}\Administrator' -f $ComputerName)
$session = New-PSSession -ComputerName $ComputerName -Credential $nodeCreds

## Show session
$session

## Show 'NetworkingDSC', if exists
Invoke-Command -Session $session -ScriptBlock {
    gci "C:\Program Files\WindowsPowerShell\Modules\NetworkingDSC" -ea Ignore
}

## Example - Prepare the copy variables
$Params = @{
    Path         = 'C:\Program Files\WindowsPowerShell\Modules\NetworkingDsc'
    Destination  = 'C:\Program Files\WindowsPowerShell\Modules\'
    ToSession    = $session
    Recurse      = $true
    Verbose      = $true
}

## Do the copy action
Copy-Item @Params


## Next, see how to execute commands on remote sessions with native PowerShell Remoting (WinRM):
psedit "C:\DSC_LABS\docs\Demo 9 - How to execute commands on remote sessions with native PowerShell Remoting (WinRM).ps1"