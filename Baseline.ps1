# An example baseline configuration for lab member servers
Configuration Baseline {
    Param (
        [Parameter(Mandatory=$true)]
        [PSCredential]$Password,
        [Parameter(Mandatory=$true)]
        [PSCredential]$Credential
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $AllNodes.NodeName
    {

        User LocalAdmin {
            Ensure = 'Present'
            UserName = 'LocalAdmin'
            Description = 'Local Administrator Account'
            Disabled = $false
            Password = $Password
        }

        Group Administrators {
            GroupName = 'Administrators'
            MembersToInclude = 'LocalAdmin'
            Ensure = 'Present'
            Credential = $Credential
            DependsOn = '[User]LocalAdmin'
        }

        User AdministratorDisable {
            UserName = 'Administrator'
            Disabled = $true
            DependsOn = '[Group]Administrators'
        }

        Service RemoteRegistry {
            Ensure = 'Present'
            Name = 'RemoteRegistry'
            StartupType = 'Automatic'
            State = 'Running'
        }

        Log Baseline {
            Message = 'Baseline configuration complete'
            DependsOn = '[Service]RemoteRegistry','[Group]Administrators'
        }
    }
}

$configdata = @{
    AllNodes = @(
     @{
      NodeName = 's1'
      Certificatefile = 'c:\certs\s1.cer'
      PSDscAllowDomainUser = $true
     }
    )
}

#Export Certificate to local authoring machine
$cert = Invoke-Command -scriptblock { 
    Get-ChildItem Cert:\LocalMachine\my | 
    Where-Object {$_.Issuer -eq 'CN=lab-CERT01-CA, DC=LAB, DC=LOCAL'}
    } -ComputerName $configdata.AllNodes.nodename

Export-Certificate -Cert $Cert -FilePath $env:systemdrive:\Certs\$($Cert.PSComputerName).cer -Force

#Generate Secure .mof  
Baseline -ConfigurationData $ConfigData `
-password (Get-Credential -UserName LocalAdmin -Message 'Enter Password') `
-Credential (Get-Credential -UserName LAB\Administrator -Message 'Enter Password') `
-OutputPath c:\dsc\s1

#establish cim session to remote node and PS session to pull server
$cim = New-CimSession -ComputerName s1
$PullSession = New-PSSession -ComputerName dscpull01

#stage pull config on pullserver
$guid = Get-DscLocalConfigurationManager -CimSession $cim `
| Select-Object -ExpandProperty ConfigurationID

$source = "C:\DSC\s1\$($ConfigData.AllNodes.NodeName).mof"
$dest = "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"

Copy-Item -Path $source -Destination $dest -ToSession $PullSession -force -verbose

Invoke-Command $PullSession -ScriptBlock {Param($ComputerName,$guid)Rename-Item $env:ProgramFiles\WindowsPowerShell\DscService\Configuration\$ComputerName.mof -NewName $env:ProgramFiles\WindowsPowerShell\DscService\Configuration\$guid.mof -Force} -ArgumentList $($ConfigData.AllNodes.NodeName),$guid
Invoke-Command $PullSession -ScriptBlock {Param($dest)New-DSCChecksum $dest -Force} -ArgumentList $dest

#invoke pull (wait a moment or two and try again if errors)
Update-DscConfiguration -CimSession $cim -Wait -Verbose

## dot source custom function for staging resources
. C:\RoboDSC\Helper-Functions\Publish-DSCResourcePull.ps1

## Use custom function to add resources to pull server if needed
$myMods = @('xTimeZone','ComputerManagementDsc','NetworkingDsc') #i.e. PSDesiredStateConfiguration,xTimeZone,ComputerManagementDsc,NetworkingDsc
Publish-DSCResourcePull -Module $myMods -ComputerName $PullSession.ComputerName

Get-DscConfigurationStatus -CimSession $cim

Invoke-Command -ComputerName $cim.ComputerName `
-ScriptBlock {net localgroup administrators}

Get-Service -ComputerName $cim.ComputerName -Name RemoteRegistry