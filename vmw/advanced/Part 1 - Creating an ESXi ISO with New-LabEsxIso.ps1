# How to create an ESXi ISO with New-LabEsxIso

## Confirm binaries
Test-Path "$env:USERPROFILE\Downloads\dos2unix-7.4.0-win64\bin\dos2unix.exe"
Test-Path "c:\Progra~2\cdrtools\mkisofs.exe"
Test-Path "$env:USERPROFILE\Downloads\VMware-VMvisor-Installer-6.7.0.update01-10302608.x86_64"

## Basic example
$params = {
    Name = 'esx01.lab.local'
    IPAddress = "10.205.1.10"
    DNSServer = "10.203.1.40,10.205.1.151,10.205.1.152"
    OutputPath = "c:\esxisos"
    Password = 'VMware123!!'
    InstallerType = 'Install'  #Install or Upgrade
    ShowKickStart = $true
    Dos2UnixPath = "$env:USERPROFILE\Downloads\dos2unix-7.4.0-win64\bin\dos2unix.exe"
    mkisofsPath = "c:\Progra~2\cdrtools\mkisofs.exe"
}

## Example using IsCryptedPassword
$params = {
    Name = 'esx01.lab.local'
    IPAddress = "10.205.1.10"
    DNSServer = "8.8.8.8"
    OutputPath = "c:\esxisos"
    IsCryptedPassword = "" #your crypted and escaped string
    InstallerType = 'Install'  #Install or Upgrade
    ShowKickStart = $true
}

## Import the module
Remove-Module New-LabEsxISO -ea Ignore
Import-Module C:\temp\New-LabEsxIso.ps1 -Verbose

## Create the ESXi ISO
New-LabEsxIso @params

## Next, learn to create a nested ESXi host (virtual machine) from the ISO:
psedit "C:\DSC_LABS\vmw\advanced\Part 2 - Creating a new virtual machine to run ESXi nested.ps1"


