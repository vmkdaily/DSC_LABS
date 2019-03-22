## This is a configuration to be pushed from an author server.
## Joins a dsc bastion node into the lab.local domain
Configuration NewTestNode {
    param (
        
        [string[]]$NodeName,
        [string]$MachineName #if different than nodename, we rename NodeName to MachineName with ComputerManagementDsc.
    )
    
    Import-DscResource -Module PSDesiredStateConfiguration,xTimeZone,ComputerManagementDsc,NetworkingDsc

    Node $AllNodes.Where{$_.Role -eq "TestNode"}.Nodename {
        
        LocalConfigurationManager
        {
            ActionAfterReboot  = 'ContinueConfiguration'
            ConfigurationMode  = 'ApplyAndAutoCorrect'
            CertificateID      = $Node.Thumbprint     #Thumbprint for node, such as a bastion cert for initial build.       
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
                DependsOn  = '[DNSServerAddress]DnsServerAddress' #will make a reasonable effort to join domain, but will move on with dsc install, so be sure your domain join technique works.
        }

        WindowsFeature TelnetClient
        {
            Ensure = "Present"
            Name   = "Telnet-Client"
            DependsOn = '[Computer]JoinStatus' #depends on not needed for this example, but shows the technique.
        }
    }
}

#Note: Be sure to highlight and run the above to bring into memory

$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = 's2'
            MachineName = 's2' #this name wins for final config over NodeName
            Role = "TestNode"
            Domain = 'lab.local'
            PsDscAllowPlainTextPassword = $false
            PSDscAllowDomainUser = $true
            IPAddress = '10.205.1.156'
            DefaultGateway = "10.205.1.1"
            DNSIPAddress = '10.205.1.151','10.205.1.152'
            Ethernet = "Ethernet0"
            Thumbprint = 'D6E9A8CFEDCCA50F6040386107A28E66D0138387'  #Thumbprint of the remote node (i.e. bastion cert for initial build).
            CertificateFile = 'C:\Certs\10.205.1.156.cer' #path to saved certificate for remote node, located on local client / authoring server. 
            Credential = (Get-Credential -UserName 'lab\administrator' -message 'Enter admin pwd for lab domain') # the login that can join nodes to lab.local.
        }
    )
}

## Highlight and run the above to save your configuration data for use below.

## Copy required resources to remote node, if needed
## For example, resources such as 'xTimeZone', 'ComputerManagementDsc', 'NetworkingDsc', etc.
psedit "C:\DSC_LABS\docs\Demo 8 - How to use Copy-Item on PowerShell 5 to copy a module for use with DSC.ps1"

#Note: Once using the pull server, the resources can be obtained automatically instead of using Copy-Item or gallery installs for remote nodes.
#We can start using the pull server later, once we join this bastion guest to the domain.

## Get remote node name. Here we use the $configData variable to read in the nodename, but you can set manually with a string value instead if desired.
$ComputerName = $ConfigData.AllNodes.NodeName

## create config and write it to local authoring machine
NewTestNode -ConfigurationData $ConfigData -OutputPath c:\dsc\NewTestNode_$ComputerName

## create new cim session for remote node using local admin
$cim = New-CimSession -ComputerName $ComputerName -Credential (Get-Credential $ComputerName\administrator)

## show cim session
$cim

## set the lcm on remote node
Set-DscLocalConfigurationManager -Path c:\dsc\NewTestNode_$ComputerName -CimSession $cim -Verbose -Force

## Optional - Get the DscLocalConfigurationManager
Get-DscLocalConfigurationManager -CimSession $cim

## start dsc config on remote node
Start-DscConfiguration -Path c:\dsc\NewTestNode_$ComputerName -CimSession $cim -Wait -Force -Verbose

## Optional - change cim session to domain credential; used for managing remote node once domain joined
$cim = New-CimSession -ComputerName $ComputerName -Credential (Get-Credential LAB\Administrator)

## Optional - get dsc config on remote node (simple detail)
Get-DscLocalConfigurationManager -CimSession $cim -Verbose

## Optional - get dsc config on remote node (lots of detail)
Get-DscConfiguration -CimSession $cim -Verbose

## Optional for pull server users only - update dsc config with the following:
Update-DscConfiguration -CimSession $cim -Wait -Verbose

## Optional - Show configuration download managers, expect none until using a pull server lcm.
Get-DscLocalConfigurationManager -CimSession $cim | Select-Object -ExpandProperty ConfigurationDownloadManagers

###############
## CHECKPOINT
###############

## Here we can stop if we only want a self-signed cert setup, fully working with dsc.
## However, since we have a pull server, we will use that now.
## This is also a good example to show that these snippets are just functions.
## We will load in the configuration below and then use it to change the LCM of the remote node.
## You will be prompted for ComputerName.

## OBJECTIVE- get domain certs and set the the lcm to use pull server
## This requires a working pull server with a certificate named `PSDSCPullServerCert`.
## Also, this requires that the node is domain joined and has obtained the default certificate from GPO or similar.

## Note: Highlight the following to make the configuration available.
## The below will import the Configuration.
## Notice we use the attribute decoration for LocalConfigurationManager which is available on PowerShell 5.x and later.

[DSCLocalConfigurationManager()]
Configuration LCM_NewTestNodePULL
{
    param
        (
            [Parameter(Mandatory=$true)]
            [string[]]$ComputerName,

            [Parameter(Mandatory=$true)]
            [string]$Guid,

            [Parameter(Mandatory=$true)]
            [string]$Thumbprint,

            [Parameter(Mandatory=$true)]
            [string]$PullThumbprint

        )
  Node $ComputerName {

    Settings {

      AllowModuleOverwrite = $True
        ConfigurationMode = 'ApplyAndAutoCorrect'
      RefreshMode = 'Pull'
      ConfigurationID = $guid
            CertificateID = $thumbprint
            }

            ConfigurationRepositoryWeb DSCHTTPS {
                ServerURL = 'https://dscpull01.lab.local:8080/PSDSCPullServer.svc'
                CertificateID = $PullThumbprint
                AllowUnsecureConnection = $False
            }
  }
}

#Note: Be sure to highlight and run the above to add the function to memory. The parameters we will populate at runtime later.

## Get the pull server certificate. Use Credential if needed, we assume your client is domain joined.
$pullServer = 'dscpull01'
$pullSession = New-PSSession -ComputerName $pullServer # use -Credential if needed
$pullCert = Invoke-Command -Session $pullSession -ScriptBlock {
    Get-ChildItem Cert:\LocalMachine\my | Where-Object {
      ($_.FriendlyName -eq 'PSDSCPullServerCert') `
      -and $_.PrivateKey.KeyExchangeAlgorithm
    }
}

## Optional - Show the pull server certificate
$pullCert

## get pull server certificate thumbprint
$pullThumbrint = $pullCert.Thumbprint

## Enter the node to manage, for example, s2 (required)
$ComputerName = Read-Host -Prompt "Enter ComputerName"

#Get remote node Certificate. This is a valid domain cert such as that created by GPO for domain-joined computers.
$nodeCert = Invoke-Command -scriptblock { 
    Get-ChildItem Cert:\LocalMachine\my | 
    Where-Object {$_.Issuer -eq 'CN=lab-CERT01-CA, DC=LAB, DC=LOCAL'}
} -ComputerName $ComputerName

## Export remote node certificate to local authoring machine. We use -Force to replace any existing of the same name.
Export-Certificate -Cert $Cert -FilePath $env:systemdrive:\Certs\$($nodeCert.PSComputerName).cer -Force

## Create a cim session to remote node (add Credential if needed)
$cim = New-CimSession -ComputerName $ComputerName

## show cim session
$cim

## Create guid
$guid=[guid]::NewGuid()

## Optional - look at exisitng LCM before proceeding. You should see it in `PUSH` mode; We will change to `PULL` for `RefreshMode` soon.
Get-DscLocalConfigurationManager -CimSession $cim

## Generate the configuration (mof output)
LCM_NewTestNodePULL -ComputerName $ComputerName `
-Guid $guid `
-Thumbprint $nodeCert.Thumbprint `
-PullThumbprint $pullThumbrint `
-OutputPath c:\DSC\LCM_NewTestNodePull_$ComputerName

## Set the lcm on remote node
Set-DscLocalConfigurationManager -CimSession $cim -Path C:\dsc\LCM_NewTestNodePull_$ComputerName -Verbose

## Get the dsc configuration; We should now see a value of PULL for the RefreshMode property.
Get-DscLocalConfigurationManager -CimSession $cim

## Show the pull server details for this node
Get-DscLocalConfigurationManager -CimSession $cim | Select-Object -ExpandProperty ConfigurationDownloadManagers

## SUMMARY
## You are now rolling with rush.
## The node in scope for this document is now fully secure and can handle any desired configuration.
## Now you can manage the node with dsc, or get another node ready by runnning the configuaration again.

## Next see how to create a baseline configuration for all of your nodes.
psedit "C:\DSC_LABS\Baseline.ps1"

## Or, work deeper on a custom LCM configuration.
psedit "C:\DSC_LABS\LCM_HTTPSPULL.ps1"

#############
## APPENDIX
#############

## How To wipe the virtual machines s1 and s2 (DeletePermanently).

## Connect to vCenter Server
$vc = 'entervcname'
$credsVC = Get-Credential administrator@vsphere.local
Connect-VIServer $vc -Credential $credsVC

## Optional - Delete test nodes s1 and s2
Get-VM 'S1','S2' | Shutdown-VMGuest -Confirm:$false
Get-VM 'S1','S2' | Remove-VM -DeletePermanently:$true -Confirm:$false

## Optional - Deploy s1 and s2 with New-LabVM
psedit "C:\DSC_LABS\docs\Demo 3 - How to deploy DSC_LABS with New-LabVM.ps1"