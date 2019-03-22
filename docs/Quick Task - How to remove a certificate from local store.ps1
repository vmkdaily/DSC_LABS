## How to remove a cert

$ComputerName = '10.205.1.153'
$creds = Get-Credential -UserName ('{0}\Administrator' -f $ComputerName) -Message 'Enter login password'
$session = New-PSSession -ComputerName $ComputerName -Credential $creds
Invoke-Command -Session $session -ScriptBlock {
     Get-ChildItem Cert:\LocalMachine\my | Remove-Item
}