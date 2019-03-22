## How to edit hosts file from ISE

## Introduction
<#
Here we can optionally configure our Windows "hosts" file.
This helps with name resolution while building out lab.local.

The Windows "hosts" file syntax is:

    ip, hostname, fqdn

#>

## Open hosts file in ISE
psedit C:\windows\system32\drivers\etc\hosts

## variable to hold our settings; Adjust as needed
$hostsContent = @"
10.205.1.151    dc01        dc01.lab.local
10.205.1.152    dc02        dc02.lab.local
10.205.1.153    cert01      cert01.lab.local
10.205.1.154    dscpull01   dscpull01.lab.local
10.205.1.155    s1          s1.lab.local
10.205.1.156    s2          s2.lab.local
10.1.2.3        vcenter01   vcenter01.somedomain.com
10.1.2.4        esx01       esx01.somedomain.com
"@

## make the change
Add-Content C:\windows\system32\drivers\etc\hosts $hostsContent

## Show details
cat C:\windows\system32\drivers\etc\hosts

## ping / test connection
Test-Connection dc01

## Summary
<#
This demo configured our local hosts file, which is optional.
Use this technique if you want to sue shortnames instead of
IP Address, even before joining nodes to the lab.local domain.
#>

## Next, learn how to use Copy-Item on PowerShell 5
psedit "C:\DSC_LABS\docs\Demo 8 - How to use Copy-Item on PowerShell 5 to copy a module for use with DSC.ps1"
