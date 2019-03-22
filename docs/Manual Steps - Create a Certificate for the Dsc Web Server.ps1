<#

## Manual Steps - Create a Certificate for the Dsc Web Server

## Step 1.  RDP to the certificate server
mstsc /v:cert01.lab.local

## Step 2.  Launch IIS Manager
From search, type `Intenet Information Services` and launch the IIS management console.

## Step 3. Server Certificates
From the IIS Management console, select your server (i.e. cert01) in the left pane.
In the right (or center) pane, double-click `Server Certificates`.
The "Server Certificates" window appears.
In the "Actions" menu on the far right, select `Create Domain Certificate`.
The "Create Certificate" window appears.
Enter values for the following "Distinguished Name Properties":

    Common Name           dscpull01.lab.local
    Organization          Lab
    Organization unit     IT
    *City/Locality        Chicago
    *State/province       Illinois
    Country/region        US

    *Do not abbreviate names for these fields

Click `Next`.
The "Online Certification Authority" screen appears.
Stay on this screen for the next step.

## Step 4. Online Certification Authority
We are still in the "Create Certificate" window, and now at the "Online Certification Authority" screen.
Here, we populate the "Specify an Online Certificate Authority" field, by clicking on `Select`.
From the menu that appears, choose the LAB.local domain.

Finally, we enter the `Friendly Name` for the certificate.

    PSDSCPullServerCert

Click `Finish`.
We are returned to the "Server Certificates" menu.
You should see your `PSDSCPullServerCert` listed there.
We will export that in the next step.

## Step 5. Export certificate to pull server
While still in the "Server Certificates" menu, locate the `PSDSCPullServerCert`.
Highlight the `PSDSCPullServerCert` in the center pane so it is selected.
In the "Actions" menu on the far right, select `Export`.
Click the elipses (`...`) to navigate to the unc path of the pull server c:\ drive.
The value for `Export To` should look similar to the following:

    \\dscpull01\c$

Finally, enter a password for certificate export.
That password is not used on anything else except to access the cert we exported.
Later (in Step 8), we will use that password when importing the certificate on the dsc pull server.

## Step 6. Log out of the certificate server
Optionally, repeat the above to create a `PSDSCComplianceServerCert`, or come back later for that.

When ready, Close IIS Manager, and logoff with `Start > Logoff` or similar.
Next, we will RDP to the pull server and import the certificate we just created.

## Step 7. RDP to Pull Server

    mstsc /v:dscpull01

## Step 8. Import Certificate on pull server
We should now be connected to the dsc pull server via RDP.
Click the yellow "Windows Explorer" icon and navigate to the `c:\` drive.
Double-click `PSDSCPullServerCert.pfx`.
The "Certificate Import Wizzard" appears.
Select `Local Machine`.
Click `Next`. 
Click `Yes` on the UAC prompt
The "File to Import" screen of the "Certificate Import Wizzard" appears.
Keep the default "File Name" as "c:\PSDSCPullServerCert.pfx".
Click `Next`.
The "Private key protection" screen of the "Certificate Import Wizzard" appears. 
Enter the password you created when exporting earlier in Step 5.
Keep the defaults for everything else.
All boxes will be unchecked except for "Include all extended properties" (this should be checked)
Click `Next`.
The "Certificate Store" screen of the "Certificate Import Wizzard" appears.
Leave the default, which is "Automatically select the certificate store based on the type of certificate".
Click `Next`.
A dialog box appears, informing you that "the import was successful." 

## Summary
This completes the setup for creating a CA certificate for use with a DSC pull server.
We created a certificate called `PSDSCPullServerCert` and made it available on the pull server.

## Next Steps, PSDSCComplianceServerCert
Optionally, repeat all above steps for the `PSDSCComplianceServerCert`. Note that using a compliance server is optional.
Further, one can use `http` instead of `https` for the compliance server, much like we can with the dsc service. However, the recommendation is to create a proper certificate; This means scroll to the top and create one called `PSDSCComplianceServerCert` and then import it onto the pull server.

## Additional Resources
This setup is based on, but not affiliated with, the Pluralsight course, "Practical Desired State Configuration (DSC)."
For a visual walkthrough, be sure to sit that course.

#>