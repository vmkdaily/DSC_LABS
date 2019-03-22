# A configuration to join a node to the lab.local domain
Configuration JoinLabDomain {

    param (
        [string]$NodeName, #this can be IP for reachability
        [string]$MachineName, #name of node. This will become the name if not already.

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module ComputerManagementDsc

    Node $AllNodes.Where{$_.Role -eq "FreshDeploy"}.Nodename {

        LocalConfigurationManager{
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            CertificateID = $Node.Thumbprint
            RebootNodeIfNeeded = $true
        }

        Node $NodeName {
            Computer JoinDomain
            {
                Name       = $Node.MachineName
                DomainName = 'lab.local'
                Credential = $Credential       # Credential to join to domain
                Server     = 'dc01.lab.local'  # domain controller to perform join operation for us
            }
        }
    }
}

$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = '10.205.1.154'
            MachineName = 'dscpull01'  #will rename node to this if needed
            Role = "FreshDeploy"
            Thumbprint = 'TODO'
            Certificatefile = "C:\Certs\10.205.1.154.cer"
            PSDscAllowDomainUser = $true
        }
    )
}

# Generate Configuration - LOGIN WITH LAB CREDENTIAL
JoinLabDomain -ConfigurationData $ConfigData `
-Credential (Get-Credential -UserName LAB\Administrator -Message 'Enter Lab Administrator login') `
-OutputPath c:\dsc\JoinLabDomain

## Handle ComputerName (recommend using NodeName)
$ComputerName = $ConfigData.AllNodes.MachineName
$ComputerName = $ConfigData.AllNodes.Nodename

## LOGIN WITH LOCAL ADMINISTRATOR
$cim = New-CimSession -ComputerName $ComputerName -Credential (Get-Credential $ComputerName\Administrator)

## Show session
$cim

## Set LCM
Set-DscLocalConfigurationManager -CimSession $cim -Path C:\dsc\JoinLabDomain -Verbose -Force

## Get LCM state
Get-DscLocalConfigurationManager -CimSession $cim | select LCMStateDetail, LCMState, PSComputerName

## Start DSC Configuration
Start-DscConfiguration -CimSession $cim -wait -force -Verbose -Path c:\dsc\JoinLabDomain\

## Get DSC Configuration status
Get-DscConfigurationStatus -CimSession $cim  |fl *

## Get DSC Cnnfiguration (detailed)
Get-DscConfiguration -CimSession $cim

## Optional - test cim with lab login
## After the system reboots, we can use FQDN.
## Edit ComputerName below:
$ComputerName = "dscpull01.lab.local"
$labCreds = Get-Credential LAB\Administrator
$cim = New-CimSession -ComputerName $ComputerName -Credential $labCreds

## Show session
$cim

## Optional - Restart your local WinRM service
Restart-Service WinRM

## Optional - Restart remote winrm
Invoke-Command -Credential $labCreds -ComputerName 10.205.1.154 -ScriptBlock {
    Restart-Service WinRM
}



