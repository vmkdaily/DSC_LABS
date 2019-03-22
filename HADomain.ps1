## A configuration for dc01 and dc02 in lab.local
## Creates a highly available domain
Configuration HADomain {

    param (
        [string]$NodeName,
        [Parameter(Mandatory)]             
        [pscredential]$SafeModeAdministratorPassword,             
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

        WindowsFeature ADDSInstall             
        {             
            Ensure = "Present"             
            Name = "AD-Domain-Services"
            IncludeAllSubFeature = $true  
        }        

        File ADFiles            
        {            
            DestinationPath = 'C:\NTDS'            
            Type = 'Directory'            
            Ensure = 'Present'            
        }            
        
        xADDomain FirstDS            
        {             
            DomainName = $Node.DomainName             
            DomainAdministratorCredential = $DomainAdministratorCredential             
            SafemodeAdministratorPassword = $SafeModeAdministratorPassword            
            DatabasePath = 'C:\NTDS'            
            LogPath = 'C:\NTDS'            
            DependsOn = "[WindowsFeature]ADDSInstall","[File]ADFiles"            
        }        
                                                
    }

    Node $AllNodes.Where{$_.Role -eq "SecondDomainController"}.Nodename
    {

        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyAndAutoCorrect'
            CertificateID = $Node.Thumbprint            
            RebootNodeIfNeeded = $true            
        }

        xDNSServerAddress DnsServerAddress
        {
            Address        = $Node.DNSIPAddress
            InterfaceAlias = $Node.Ethernet
            AddressFamily  = 'IPV4'
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            IncludeAllSubFeature = $false
            DependsOn = "[xDNSServerAddress]DnsServerAddress"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainName
            DomainUserCredential = $DomainAdministratorCredential
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
        
        xADDomainController SecondDC
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $DomainAdministratorCredential
            SafemodeAdministratorPassword = $SafeModeAdministratorPassword
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xADRecycleBin RecycleBin {
            EnterpriseAdministratorCredential = $DomainAdministratorCredential
            ForestFQDN = $Node.DomainName
            DependsOn = "[xADDomainController]SecondDC"
        }
    }    
}

## Create sessions
$session1 = New-PSSession -ComputerName '10.205.1.151' -Credential (Get-Credential LAB\Administrator)
$session2 = New-PSSession -ComputerName '10.205.1.152' -Credential (Get-Credential 10.205.1.152\Administrator)

## Get any valid local cert. You can get more specific by using FriendlyName or similar (not shown here).
$cert1 = Invoke-Command -Session $session1 -ScriptBlock {
    [string]$strName = cat env:ComputerName
    Get-ChildItem Cert:\LocalMachine\my | Where-Object { $_.PrivateKey.KeyExchangeAlgorithm }
}
$cert2 = Invoke-Command -Session $session2 -ScriptBlock {
    [string]$strName = cat env:ComputerName
    Get-ChildItem Cert:\LocalMachine\my | Where-Object { $_.PrivateKey.KeyExchangeAlgorithm }
}

## Extract thumbprints
$thumbprint1 = $cert1.thumbprint
$thumbprint2 = $cert2.thumbprint

##Show thumbprints (add to config data for nodes below)
$thumbprint1
$thumbprint2

## Note: When a machine gets promoted to a domain controller,
## the local machine password (RID500 a.k.a. Administrator)
## will become the domain password.
## Optionally, set the password first
psedit "C:\DSC_LABS\SetLocalAdminPw.ps1"

# Note: We expect Certificatefile (i.e. c:\certs\10.205.1.151.cer)
# for each node to already be saved locally on client / authoring machine.

$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = '10.205.1.151'          
            Role = "FirstDomainController"
            DomainName = "lab.local"
            DNSIPAddress  = '10.203.1.40'
            Ethernet   = 'Ethernet0'                       
            Thumbprint = 'E0507137A5288D39316CA8FFC933D44F5385E6C5'
            Certificatefile = 'c:\certs\10.205.1.151.cer'
            RetryCount = 20
            RetryIntervalSec = 30            
            PSDscAllowDomainUser = $true     
        }

        @{             
            Nodename = '10.205.1.152'          
            Role = "SecondDomainController"
            DomainName = "lab.local"
            DNSIPAddress  = '10.205.1.151'
            Ethernet   = 'Ethernet0'                       
            Thumbprint = '8A178267D608081EF55FD1D4AA4B73FE012EDB4D'
            Certificatefile = 'c:\certs\10.205.1.152.cer'
            RetryCount = 20
            RetryIntervalSec = 30            
            PSDscAllowDomainUser = $true     
        }               
    )             
}

# Generate Configuration
HADomain -ConfigurationData $ConfigData `
-SafeModeAdministratorPassword (Get-Credential -UserName '(Password Only)' `
-Message "New Domain Safe Mode Administrator Password") `
-DomainAdministratorCredential (Get-Credential -UserName lab\administrator `
-Message "New Domain Admin Credential") -OutputPath c:\dsc\HADomain

## Create cim sessions
$cim1 = New-CimSession -ComputerName 10.205.1.151 -Credential (Get-Credential LAB\Administrator)
$cim2 = New-CimSession -ComputerName 10.205.1.152 -Credential (Get-Credential 10.205.1.152\Administrator) 

## Show sessions
$cim1
$cim2

## set on local node
Set-DscLocalConfigurationManager -CimSession $cim1, $cim2 -Path c:\dsc\HADomain -Verbose -Force

## start on local node
Start-DscConfiguration -CimSession $cim1, $cim2 -wait -force -Verbose -Path c:\dsc\HADomain

## set on remote node
Set-DscLocalConfigurationManager -CimSession $cim1, $cim2 -Path c:\dsc\HADomain -Verbose -Force 

## start on remote node
Start-DscConfiguration -CimSession $cim1, $cim2 -wait -force -Verbose -Path c:\dsc\HADomain

## Optional
Get-DscLocalConfigurationManager -CimSession $cim1, $cim2
Get-DscLocalConfigurationManager -CimSession $cim1, $cim2