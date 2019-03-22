## A configuration to create the first domain controller in lab.local
Configuration NewDomain {

    param (

        #PSCredential. The safe mode administrator credential.
        [Parameter(Mandatory)]
        [pscredential]$SafeModeAdministratorPassword,

        #PSCredential. The credential used to query for domain existence.
        [Parameter(Mandatory)]
        [pscredential]$DomainAdministratorCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xNetworking

    Node $AllNodes.Where{$_.Role -eq "FirstDomainController"}.Nodename  {

        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            CertificateID = $Node.Thumbprint
            RebootNodeIfNeeded = $true
        }

        xIPAddress IPAddress
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = $Node.Ethernet
            #SubnetMask     = 16
            AddressFamily  = "IPV4"
        }

        xDefaultGatewayAddress DefaultGateway
        {
            AddressFamily = 'IPv4'
            InterfaceAlias = $Node.Ethernet
            Address = $Node.DefaultGateway
            DependsOn = '[xIPAddress]IpAddress'
        }

        xDNSServerAddress DnsServerAddress
        {
            Address        = $Node.DNSIPAddress
            InterfaceAlias = $Node.Ethernet
            AddressFamily  = 'IPV4'
        }

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS"
        }

        File ADFiles
        {
            DestinationPath = 'C:\NTDS'
            Type = 'Directory'
            Ensure = 'Present'
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            IncludeAllSubFeature = $true
        }

        xADDomain FirstDC
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $DomainAdministratorCredential
            SafemodeAdministratorPassword = $SafeModeAdministratorPassword
            DatabasePath = 'C:\NTDS'
            LogPath = 'C:\NTDS'
            DependsOn = "[WindowsFeature]ADDSInstall","[File]ADFiles"
        }                                         
    }
}

$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = '10.205.1.151'
            Role = "FirstDomainController"
            DomainName = "lab.local"
            IPAddress = '10.205.1.151'
            DefaultGateway = '10.205.1.1'
            DNSIPAddress = '127.0.0.1'
            Ethernet = 'Ethernet0'
            Thumbprint = '7F4A0EAFB54EE9D290ABB0D99214F59C7E11A92C'
            Certificatefile = "C:\Certs\10.205.1.151.cer"
            PSDscAllowPlainTextPassword = $false
            PSDscAllowDomainUser = $true
        } 
    )
}

## Create session
$ComputerName = $Configdata.allnodes.NodeName
$Credential = (Get-Credential -UserName $ComputerName\Administrator -Message 'Enter guest login')
$session = New-PSSession -ComputerName $ComputerName -Credential $Credential

## Show session
$session

## Get any valid local cert. You can get more specific by using FriendlyName or similar (not shown here).
$cert = Invoke-Command -Session $session -ScriptBlock {
    [string]$strName = cat env:ComputerName
    Get-ChildItem Cert:\LocalMachine\my | Where-Object { $_.PrivateKey.KeyExchangeAlgorithm }
}

## Show the cert
$cert  |fl *

## Extract thumbprint
$thumbprint = $cert.thumbprint

##Show thumbprint
$thumbprint

## Note: When a machine gets promoted to a domain controller,
## the local machine password (RID500 a.k.a. Administrator)
## will become the domain password.
## Optionally, set the password first
psedit "C:\DSC_LABS\SetLocalAdminPw.ps1"


## Generate Configuration
NewDomain -ConfigurationData $ConfigData `
-SafeModeAdministratorPassword (Get-Credential -UserName '(Password Only)' `
-Message "New Domain Safe Mode Administrator Password") `
-DomainAdministratorCredential (Get-Credential -UserName lab\administrator `
-Message "New Domain Admin Credential") `
-OutputPath c:\dsc\NewDomain

## Create cim sessions
$cim = New-CimSession -ComputerName 10.205.1.151 -Credential (Get-Credential 10.205.1.151\Administrator)

## Show cim session
$cim

## Set LCM
Set-DscLocalConfigurationManager -CimSession $cim -Path c:\dsc\NewDomain -Verbose -Force

## Optional - Get LCM state
Get-DscLocalConfigurationManager -CimSession $cim | select LCMStateDetail, LCMState, PSComputerName

## Start DSC Configuration
Start-DscConfiguration -CimSession $cim -wait -force -Verbose -Path c:\dsc\NewDomain\

## Get DSC Configuration Status
Get-DscConfigurationStatus -CimSession $cim

## Optional - Update cim session
$labCreds = Get-Credential LAB\Administrator
$cim = New-CimSession -ComputerName 10.205.1.151 -Credential $labCreds

## Show session
$cim

## Get LCM config
Get-DscLocalConfigurationManager -CimSession $cim

## Get DSC configuration status
Get-DscConfigurationStatus -CimSession $cim

## Get DSC configuration:
Get-DscConfiguration -CimSession $cim



