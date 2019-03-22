## How to remove a dsc configuration document

# create cim session
$cim = New-CimSession -ComputerName 'somenode'

# Remove a dsc document. Choices are Current, Pending, or Previous.
Remove-DscConfigurationDocument -CimSession $cim -Stage Current