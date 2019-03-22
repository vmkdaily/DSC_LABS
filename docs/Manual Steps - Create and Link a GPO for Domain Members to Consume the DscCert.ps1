<#

## Manual Steps - Create and Link a GPO for Domain Members to Consume the DscCert

## Step 1.  RDP to domain controller, if needed

    mstsc /v:dc01.lab.local

## Step 2. Launch an elevated PowerShell or ISE
## From the domain controller, right-click and run PowerShell
## or ISE as Administrator (UAC), and then proceed.

## Step 3. Create New-GPO

    $comment = "AutoEnrolls Computers for the DscCert issued by the ADCS Cert server"
    New-GPO -Name Cert-AutoEnroll -Comment $comment

## Step 4. Change GPO Status

    (Get-GPO "Cert-AutoEnroll").gpostatus="UserSettingsDisabled"

## Step 5. Launch the Group policy mmc

    $mmcPath = "c:\Windows\System32\mmc.exe"
    $mscPath = "c:\Windows\System32\gpmc.msc"
    Start-Process -FilePath $mmcPath -ArgumentList $mscPath

    # [manual steps] - From the mmc gui
    <#
    - Navigate to "Forest > Domains > Lab.local > Group Policy Objects"
    - Right-click `Cert-AutoEnroll` and select `Edit`.
    - The "Group Policy Management Editor" window appears.
    - Navigate to "Computer Configuration > Policies > Windows Settings > Security"
    - With the `Security` tab expanded, select the "Public Key Policies" folder in the left pane.
    - In the right pane, locate and double-click `Certificate Services Client - Auto-Enrollment`.
    - The `Certificate Services - Auto-Enrollment Properties` window appears.
    - Set the `Configuration Model` to `Enabled`;
    - Check the box for "Renew expired certificates, update pending certificates, and remove revoked certificated"
    - Check the box for "Update certificates that use certificate templates"
    - Click `OK`.
    - Close "Group Policy Management Editor".
    - You are returned to the "Group Policy Management" console; Keep this open for the next step.
    Next, we will link the GPO to the domain.

## Step 6. Important - Link GPO to "lab.local" domain
We have closed the "Group Policy Management Editor" and have the "Group Policy Management" console open. 
from here, we will link the GPO to the root of the domain.

In "Group Policy Management" console, navigate to "Forest > Domains > Lab.local".
Right-click lab.local (or your domain) and select `Link an Existing GPO`.
Under "Group Policy Objects" section, select `Cert-AutoEnroll` and click `OK`.

Note: If desired, you could do the above at the OU level instead the entire domain.

## Summary
## The GPO is now ready and all domain members should get it automatically.

## Break time
## This is a good time for a break while the GPO populates the certificate on domain nodes.

## APPENDIX -  Optional Testing
Here, we get the certificate from a domain member using PowerShell, if it exists.

    ## assumes client and target are in the domain
    $session = New-PSSession -ComputerName dscpull01.lab.local

    ## Show session
    $session

    ## show any cert
    Invoke-Command -Session $session -ScriptBlock { Get-ChildItem Cert:\LocalMachine\my }

    ## Get lab.local cert from node
    $cert = Invoke-Command -Session $session -ScriptBlock {
        Get-ChildItem Cert:\LocalMachine\my | 
        Where-Object {$_.Issuer -eq 'CN=lab-CERT01-CA, DC=LAB, DC=LOCAL' `
        -and $_.PrivateKey.KeyExchangeAlgorithm `
        }
    }

    #show the cert
    $cert

    #show cert detail
    $cert | fl *

    #Optional - Reboot remote node
    Invoke-Command -Session $session -ScriptBlock {
        gpupdate /force
        #Restart-Computer -Force
    }

## Additional Resources
This setup is based on the Pluralsight course, "Practical Desired State Configuration (DSC)."
For a visual walkthrough, be sure to sit that course.

#>