# A configuration to Set the IP Address of a remote node
Configuration SetNodeIPAddress {

    Import-DscResource -ModuleName xNetworking

    Node $AllNodes.Where{$_.Role -eq "FreshDeploy"}.Nodename {

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
    }
}

$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = '10.205.1.154'
            Role = "FreshDeploy"
            IPAddress = '10.205.1.154'
            DefaultGateway = '10.205.1.1'
            DNSIPAddress = '10.203.1.151','10.205.1.152'
            Ethernet    = 'Ethernet0'
            Thumbprint = '7BA04BC3695E36C29EDC1F8FC4E0ACC66A475103'
            Certificatefile = "C:\Certs\10.205.1.154.cer"
        }
        
    )
}

# Generate Configuration
SetNodeIPAddress -ConfigurationData $ConfigData -OutputPath c:\dsc\SetNodeIPAddress

## Create cim session
$cim = New-CimSession -ComputerName 10.205.1.154 -Credential (Get-Credential 10.205.1.154\Administrator)

## Show session
$cim

## Set LCM
Set-DscLocalConfigurationManager -CimSession $cim -Path C:\dsc\SetNodeIPAddress -Verbose -Force

## Get LCM state
Get-DscLocalConfigurationManager -CimSession $cim | select LCMStateDetail, LCMState, PSComputerName

## Start DSC Configuration
Start-DscConfiguration -CimSession $cim -wait -force -Verbose -Path c:\dsc\SetNodeIPAddress\
