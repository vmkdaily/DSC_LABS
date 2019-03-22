# An example LCM for consumption via https pull server.
[DSCLocalConfigurationManager()]
Configuration LCM_HTTPSPULL
{
    param
        (
            [Parameter(Mandatory=$true)]
            [string[]]$ComputerName,

            [Parameter(Mandatory=$true)]
            [string]$Guid,

            [Parameter(Mandatory=$true)]
            [string]$Thumbprint

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
                CertificateID = 'TODO'
                AllowUnsecureConnection = $False
            }
	}
}

## Enter the node to manage, for example, s2 (required). Should be in the domain already (i.e. lab.local)
$ComputerName = Read-Host -Prompt "Enter ComputerName"

## Use the custom function, Export-MachineCert to get the desired cert info from remote node
$Cert = Export-MachineCert -computername $ComputerName -Path C:\Certs

## Create a cim session to remote node
$cim = New-CimSession -ComputerName $ComputerName

## Create guid
$guid=[guid]::NewGuid()

## Generate the configuration (mof output)
LCM_HTTPSPULL -ComputerName $ComputerName -Guid $guid -Thumbprint $Cert.Thumbprint -OutputPath c:\dsc\HTTPS

## Set the lcm on remote node
Set-DscLocalConfigurationManager -CimSession $cim -Path C:\dsc\HTTPS -Verbose
