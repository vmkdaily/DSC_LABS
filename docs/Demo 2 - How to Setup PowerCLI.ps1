## How to set up PowerCLI

Install-Module -Name VMware.PowerCLI

## Show current configuration
Get-PowerCLIConfiguration  | fl *

## Variables for config
$sParam = @{
    DefaultVIServerMode           = 'Single'   #default is multiple
    ProxyPolicy                   = 'NoProxy'
    ParticipateInCEIP             =  $false
    CEIPDataTransferProxyPolicy   = 'NoProxy'
    DisplayDeprecationWarnings    = $false
    InvalidCertificateAction      = 'Ignore'
    WebOperationTimeoutSeconds    = 600
    VMConsoleWindowBrowser        = ''
    Scope                         = 'User'
    Confirm                       = $false
}

## Set config
Set-PowerCLIConfiguration @sParam -Verbose

## Example profile entry for ise profile. Not needed for console profile.
## Optionally, import the PowerCLI module into the ISE
#<
    cat $profile

    ## My ISE profile
    Set-Location C:\DSC_LABS
    Import-Module VMware.PowerCLI

#>

## Next, we learn to deploy virtual machines with New-LabVM:
psedit "C:\DSC_LABS\docs\Demo 3 - How to deploy DSC_LABS with New-LabVM.ps1"




