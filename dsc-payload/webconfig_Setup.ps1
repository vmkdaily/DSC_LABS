## Configure Web.Config for use with PowerShell DSC v5 Configuration Names and RegistrationKey
## From blog post:
## http://www.xipher.dk/WordPress/?p=803

$FilePath = 'C:\inetpub\wwwroot\PSDSCPullServer\web.config'

[XML]$WebConfig = Get-Content $FilePath
$WebConfig.configuration.appSettings.ChildNodes
notepad.exe 'C:\inetpub\wwwroot\PSDSCPullServer\web.config'


$RegistrationKeyPath = $WebConfig.SelectSingleNode("//configuration/appSettings/add[@key='RegistrationKeyPath']")
If ($RegistrationKeyPath )
{
    Write-Warning -Message "RegistrationKeyPath allready exists. With the value $($RegistrationKeyPath.Value), exiting"
}       
Else 
{    
    $RegistrationKeyPath = $WebConfig.CreateNode('element','add','')    
    $RegistrationKeyPath.SetAttribute('key', 'RegistrationKeyPath')
    $RegistrationKeyPath.SetAttribute('value', 'C:\Program Files\WindowsPowerShell\DscService' )
    $appSettingsNode = $WebConfig.SelectSingleNode('//configuration/appSettings').AppendChild($RegistrationKeyPath)
    $WebConfig.Save($FilePath)
    notepad.exe 'C:\inetpub\wwwroot\PSDSCPullServer\web.config'
}


Set-Content  -Path 'C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt' -Value 'MySecureKey'