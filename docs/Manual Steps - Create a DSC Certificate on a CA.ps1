
## Manual Steps - Create a DSC Certificate on a CA

<#

## Step 1.  RDP to certificate server
mstsc /v:cert01.lab.local

## Step 2. Launch mmc
Copy/Paste the following into PowerShell.

    $mmcPath = "c:\Windows\System32\mmc.exe"
    $mscPath = "c:\Windows\system32\certsrv.msc"
    Start-Process -FilePath $mmcPath -ArgumentList $mscPath

Note: If running remotely (i.e. not RDP'd into the cert01 server), ignore the error "the specified service does not exist..." and retarget / browse to the desired remote CA.

## Step 3. Connect to CA
You should see your CA listed such as lab.local.
Expand the CA to show the structure below.

## Step 4. Navigate to `Certificate Templates`
Right-click `Certificate Templates` and select `Manage`.

## Step 5. Navigate to `Workstation Authentication`
In the right pane, locate and right-click `Workstation Authentication` and select `Duplicate Template`.

## Step 6. Fill out desired options
    
    #General Tab                              Value/Setting
    Template Display Name                     DscCert
    Template Name                             DscCert
    Publish certificate in Active Directory   Check the box
    Do not automatically reenroll...          unchecked

    #Subject Name Tab                         Value/Setting
    Subject name format                       Common name

    #Extensions Tab                           Value/Setting
    Application Policies                      double-click

        In the "Edit Application Policies Extension" window, select "Client Authentication" and remove it.
        
        Next, click `Add` and select `Document Encryption` and click `OK`.

        We are now back at the "Properties of New Template" window, on the `Extensions` tab.

        Next, we change to the `Security` tab.

    ## Security tab
    While still in the "Properties of New Template", locate the `Security` tab.
    Select `Domain Computers` from the `Group or User Names` section.
    In the `Permissions for Domain Computers` section, check the box to Allow `Autoenroll`.
    Click `Apply` and then click `OK`.

    You are returned to the `Certificate Templates` window.
    Here, you can see the newly created `DscCert` now exists.
    Next we go back to the CA Console where we first started.
    You can close the Certificate Console, and return to the main CA mmc.

    ## Break Time
    The CA will not become aware of the new `dsccert` template until all domain controllers have replicated.
    As such, you may need to wait longer than expected for the next step to work.
    If you will not take a break now, reboot the cert server and both DCs.

    ## Add certificate Template
    From the CA Console, right-click `Certificate Templates`;
    Select `New` > `Certificate Template to Issue`.
    The `Enable Certificate Template` window appears.
    Select `DscCert` and click `OK`.

    > Note: If the `dsccert` does not appear in the list, you must wait more time.


## Summary
The `DscCert` has been added as a template to the CA.
Next, we will add this to an Active Directory GPO, so all domain computers get the certificate.

## Additional Resources
This setup is based on, but not affiliated with, the Pluralsight course, "Practical Desired State Configuration (DSC)."
For a visual walkthrough, be sure to sit that course.

> Note: In the Pluralsight course, the config used "Client", and "Server" encryption as well.
This walkthrough uses only the "Document Encryption" application policy type which is all DSC needs.

#>