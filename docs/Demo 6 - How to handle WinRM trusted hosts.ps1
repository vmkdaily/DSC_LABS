## How to handle WinRM trusted hosts

## Introduction
<#
This example shows how to prepare your local client to communicate via WinRM to remote nodes.
With kerberos and an existing domain this would not be needed.
Here we need to connect to new nodes that are not in a domain yet, nor are we with our jump box / client perhaps.
We can set these WinRM allowances and then change them back later.
#>

## Prerequisites
The guest firewall is open for WinRM and the node can be reached on the network by name or IP Address.

## winrm quick config
## Use the "winrm quick config" (or "winrm qc") to open your local firewall.

    winrm quickconfig

<#
Note: If already set, it will return:

    WinRM service is already running on this machine.
    WinRM is already set up for remote management on this computer.
#>

## Get WinRM trusted list
$trusted = (Get-Item WSMan:\localhost\Client\TrustedHosts)
$trusted

## Set WinRM to trust "10.*"
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.*"

## Get again
$trusted = (Get-Item WSMan:\localhost\Client\TrustedHosts)
$trusted

## show trusted value
$trusted.Value

## Set and include 'DC01' (or any other name)
$trusted = (Get-Item WSMan:\localhost\Client\TrustedHosts)
$value = ($trusted.value).tostring()
$newItem = 'dc01'
$updated = ('{0},{1}' -f $value, $newItem)
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $updated

## Get again
$trusted = (Get-Item WSMan:\localhost\Client\TrustedHosts)
$trusted

## example output
<#
    $trusted = (Get-Item WSMan:\localhost\Client\TrustedHosts)
    $trusted


       WSManConfig: Microsoft.WSMan.Management\WSMan::localhost\Client

    Type            Name                           SourceOfValue   Value                                                                                                         
    ----            ----                           -------------   -----                                                                                                         
    System.String   TrustedHosts                                   10.*,dc01
#>

## Set and include 'DC02'
## This requires $trusted variable is populated from any of previous steps
$value = ($trusted.value).tostring()
$newItem = 'dc02'
$updated = ('{0},{1}' -f $value, $newItem)
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $updated

## Get again
$trusted = (Get-Item WSMan:\localhost\Client\TrustedHosts)
$trusted

## Summary
<#
This demo shows the basic setup to get our local WinRM client configured.
The configuration is secure by default, so we need to allow the nodes
we are building one by one. We did that and confirmed we can reach the nodes.
#>

## Next, we configure our client "hosts" file:
psedit "C:\DSC_LABS\docs\Demo 7 - How to edit hosts file.ps1"

#############
## APPENDIX
#############

## Other "winrm" commands
winrm e winrm/config/listener
winrm get winrm/config
wmimgmt.msc
