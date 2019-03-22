# A configuration to set the local admin password
Configuration SetLocalAdminPw {

    param (
        [string]$NodeName,

        [Parameter(Mandatory)]
        [pscredential]$NewCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $AllNodes.Where{$_.Role -eq "FreshDeploy"}.Nodename {

        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            CertificateID = $Node.Thumbprint
            RebootNodeIfNeeded = $true
        }

        User RID500_Pass
        {
            UserName = "Administrator"
            Password = $NewCredential
        }
    }
}

$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = '10.205.1.154'
            Role = "FreshDeploy"
            Thumbprint = '7BA04BC3695E36C29EDC1F8FC4E0ACC66A475103'
            Certificatefile = "C:\Certs\10.205.1.154.cer"
        }
        
    )
}

# Generate Configuration
SetLocalAdminPw -ConfigurationData $ConfigData `
-NewCredential (Get-Credential -UserName Administrator -Message 'Enter new password') `
-OutputPath c:\dsc\SetLocalAdminPw

## Create cim session - CURRENT TEMPLATE PASSWORD
$ComputerName = $ConfigData.AllNodes.Nodename
$cim = New-CimSession -ComputerName $ComputerName -Credential (Get-Credential $ComputerName\Administrator)

## Show session
$cim

## Set LCM
Set-DscLocalConfigurationManager -CimSession $cim -Path C:\dsc\SetLocalAdminPw -Verbose -Force

## Get LCM state
Get-DscLocalConfigurationManager -CimSession $cim | select LCMStateDetail, LCMState, PSComputerName

## Start DSC Configuration
Start-DscConfiguration -CimSession $cim -wait -force -Verbose -Path c:\dsc\SetLocalAdminPw\

## Optional - test new cim password
$ComputerName = $ConfigData.AllNodes.Nodename
$cim = New-CimSession -ComputerName $ComputerName -Credential (Get-Credential $ComputerName\Administrator)

## Show session
$cim
