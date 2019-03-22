## This is a configuration to be pushed from an author server, in order to deploy a new dsc pull server
Configuration NewPullServer {
    param (
        
        [string[]]$NodeName,
        [string]$MachineName  #if different than nodename, we rename NodeName to MachineName using ComputerManagementDsc.
    )
    
    Import-DscResource -Module PSDesiredStateConfiguration,xPSDesiredStateConfiguration,xTimeZone,ComputerManagementDsc,NetworkingDsc

    Node $AllNodes.Where{$_.Role -eq "HTTPSPull"}.Nodename {
        
        LocalConfigurationManager
        {
            ActionAfterReboot  = 'ContinueConfiguration'
            ConfigurationMode  = 'ApplyAndAutoCorrect'
            CertificateID      = $Node.Thumbprint     #Thumbprint for dscpull01, such as a bastion cert for initial build.       
            RebootNodeIfNeeded = $true
        }
        
        xTimeZone SystemTimeZone {
            TimeZone = 'Central Standard Time'
            IsSingleInstance = 'Yes'

        }

        IPAddress NewIPAddress
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = $Node.Ethernet
            #SubnetMask     = 16
            AddressFamily  = "IPV4"
        }

        DefaultGatewayAddress NewDefaultGateway
        {
            AddressFamily = 'IPv4'
            InterfaceAlias = $Node.Ethernet
            Address = $Node.DefaultGateway
            DependsOn = '[IPAddress]NewIpAddress'

        }
        
        DNSServerAddress DnsServerAddress
        {
            Address        = $Node.DNSIPAddress
            InterfaceAlias = $Node.Ethernet
            AddressFamily  = 'IPV4'
        }
        
        Computer JoinStatus
        {
                Name       = $Node.MachineName
                DomainName = $Node.Domain
                Credential = $Node.Credential
                Server     = 'dc01.lab.local' #domain controller for join
                DependsOn  = '[DNSServerAddress]DnsServerAddress' #will make a reasonable effort to join domain, but will move on with dsc install, so be sure your domain join technique works, or do the join in a dedicated configuration first.
        }

        WindowsFeature DSCServiceFeature
        {
            Ensure = "Present"
            Name   = "DSC-Service"
            DependsOn = '[Computer]JoinStatus'
        }

        WindowsFeature IISConsole {
            Ensure = "Present"
            Name   = "Web-Mgmt-Console"
        }

        xDscWebService PSDSCPullServer
        {
            Ensure                  = "Present"
            UseSecurityBestPractices = $true
            EndpointName            = "PSDSCPullServer"
            Port                    = 8080
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint   = $Node.CertificateThumbPrint #Thumbprint of PSDSCServerCert created in IIS.
            ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State                   = "Started"
            RegistrationKeyPath     = "$env:PROGRAMFILES\WindowsPowerShell\DscService"
            DependsOn               = "[WindowsFeature]DSCServiceFeature"
        }

        xDscWebService PSDSCComplianceServer
        {
            Ensure                  = "Present"
            UseSecurityBestPractices = $true
            EndpointName            = "PSDSCComplianceServer"
            Port                    = 9080
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
            CertificateThumbPrint   = $Node.ComplianceCert    #optionally, make another cert for compliance server, or 'AllowUnencryptedTraffic'. 
            State                   = "Started"
            DependsOn               = ("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
        }
    }
}

#Note: Be sure to highlight and run the above to bring into memory

$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = '10.205.1.154' #This should only be IP address if needed to reach.
            MachineName = 'dscpull01' #The node will be renamed if needed; MachineName wins for final config over NodeName
            Role = "HTTPSPull"
            Domain = 'lab.local'
            PsDscAllowPlainTextPassword = $false  #the default is $false so this is not required.
            PSDscAllowDomainUser = $true
            IPAddress = '10.205.1.154'
            DefaultGateway = "10.205.1.1"
            DNSIPAddress = '10.205.1.151','10.205.1.152'
            Ethernet = "Ethernet0"
            CertificateThumbPrint   = '9B4187ACEB649D3ADBDBA3E6DBE824574721966B'  #Thumbprint of PSDSCPullServerCert created in IIS.
            Thumbprint              = 'TODO'  #Thumbprint of the dscpull01 node (i.e. bastion cert for initial build. Can also be from lab.local GPO-provided cert if domain joined).
            CertificateFile         = 'C:\Certs\10.205.1.154.cer'  #path on authoring server to saved certificate for dscpull01 (i.e. bastion cert for initial build).
            ComplianceCert          = '01137166BDBACBF427DA02D0704AB406E73C2906'  #compliance server cert created on cert01 server for dsc pull server compliance server.
            Credential = (Get-Credential -UserName 'lab\administrator' -message 'Enter admin pwd for lab domain') # Used to join remote node to lab.local if needed.
        }
    )
}


## Session setup
$error.clear();clear
$guest = '10.205.1.154'  #IP Address or name of guest node to manage.
$creds = Get-Credential "$guest\Administrator"
$session = New-PSSession -ComputerName $guest -Credential $creds

## Confirm session is active
$session

## show both certs
Invoke-Command -Session $session -ScriptBlock {
    Get-ChildItem Cert:\LocalMachine\my | ?{$_.FriendlyName -eq 'PSDSCPullServerCert' `
    -or $_.FriendlyName -eq 'PSDSCComplianceServerCert'} | `
    Select-Object Thumbprint,Subject,FriendlyName,EnhancedKeyUsageList
}

## Get the pull server iis cert

$PullCert = Invoke-Command -Session $session -ScriptBlock {
    Get-ChildItem Cert:\LocalMachine\my | Where-Object { $_.FriendlyName -eq "PSDSCPullServerCert" }
}

## Show pull cert
Write-Host "//pull cert"
$PullCert

## Get the compliance server iis cert
$ComplianceCert = Invoke-Command -Session $session -ScriptBlock {
    Get-ChildItem Cert:\LocalMachine\my | Where-Object { $_.FriendlyName -eq "PSDSCComplianceServerCert" }
}

## Show compliance cert
Write-Host "//compliance cert"
$ComplianceCert

## create config and write it to local authoring machine
NewPullServer -ConfigurationData $ConfigData -OutputPath c:\dsc\NewPullServer

## create new cim session for remote node (adjust login if not domain-joined yet)
$cim = New-CimSession -ComputerName 'dscpull01' -Credential (Get-Credential lab\administrator)

## show cim session
$cim

## set the lcm on remote node
Set-DscLocalConfigurationManager -Path c:\dsc\NewPullServer -CimSession $cim -Verbose -Force

## start dsc config on remote node
Start-DscConfiguration -Path c:\dsc\NewPullServer -CimSession $cim -Wait -Force -Verbose

## Optional - get dsc config on remote node (lots of detail)
Get-DscConfiguration -CimSession $cim -Verbose

## Optional - get dsc config on remote node (simple detail)
Get-DscLocalConfigurationManager -CimSession $cim -Verbose

## Show configuration download managers, expect none until using a pull server lcm.
Get-DscLocalConfigurationManager -CimSession $cim | Select-Object -ExpandProperty ConfigurationDownloadManagers

##Optional - Review health of dsc web page (xml format, viewable in ie or similar)
Start-Process -FilePath iexplore.exe https://10.205.1.154:8080/PSDSCPullServer.svc