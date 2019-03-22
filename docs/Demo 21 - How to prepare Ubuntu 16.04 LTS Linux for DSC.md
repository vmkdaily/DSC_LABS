## How to prepare Ubuntu 16.04 LTS Linux for DSC
This document is a guide to get Desired State Configuration (DSC) running on Ubuntu 16.04 Linux.

## Documentation for PowerShell DSC for Linux
Visit the official github project page for the latest details and other supported distributions.

    https://github.com/Microsoft/PowerShell-DSC-for-Linux


## Base Install
Perform the installation of Ubuntu 16.04 from ISO or similar using the typical settings as desired.
When prompted, create a user and set desired password. All instructions below will use sudo.

## Update system

    sudo apt -y update
    sudo apt -y upgrade

## Install Prerequisite, `python-ctypes`
Here we install the only requirement to get us up and running.

    sudo apt install python-ctypes

## Optional - Enable ssh on remote node
To use putty or similar to reach the remote node, we can install `openssh-server`.
We will not use root login, so there is no need to edit files or restart services.

    sudo apt -y install openssh-server

## Download and Install `omi` and `dsc`
Perform the following to use `wget` and `dpkg` to download and install the supported bits.

    #download omi
    wget https://github.com/Microsoft/omi/releases/download/v1.1.0-0/omi-1.1.0.ssl_100.x64.deb

    #download dsc
    wget https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_100.x64.deb

    #install both packages (omi and dsc)
    sudo dpkg -i omi-1.1.0.ssl_100.x64.deb dsc-1.1.1-294.ssl_100.x64.deb

> Note: The officially supported versions required for dsc will lag behind the latest for omi, so see appendix if wanting latest.

## Optional - Get service status for `omid`
Because we used `apt` to install `omi`, the app is automatically added to systemd.
Here, we just get `status` but after changing the config file later we will use `restart`.

    sudo systemctl status omid

## Optional - Show the `omi` binaries
Optionally, have a look around at the `omi` binaries located at `/opt/omi/bin/`.

    mike@linux01:~$ ls -lh /opt/omi/bin/
    total 13M
    lrwxrwxrwx 1 root root   41 Feb 11 19:35 ConsistencyInvoker -> /opt/microsoft/dsc/bin/ConsistencyInvoker
    -rwxr-xr-x 1 root root 3.0M Aug 16  2016 omiagent
    -rwxr-xr-x 1 root root 723K Aug 16  2016 omicheck
    -rwxr-xr-x 1 root root 2.3M Aug 16  2016 omicli
    -rwxr-xr-x 1 root root 156K Aug 16  2016 omiconfigeditor
    -rwxr-xr-x 1 root root 1.7M Aug 16  2016 omigen
    -rwxr-xr-x 1 root root 353K Aug 16  2016 omireg
    -rwxr-xr-x 1 root root 4.0M Aug 16  2016 omiserver
    -rwxr-xr-x 1 root root 4.8K Aug 16  2016 service_control
    drwxr-xr-x 2 root root 4.0K Feb 11 19:35 support

## Configure `omid` service
Enter an editor such as `vi` or `nano` to edit the config file.

    sudo nano /etc/opt/omi/conf/omiserver.conf

## Allow `http` and/or `https`.
By default your config file will be `httpport=0` which disables it.
As an example for an insecure test, we will allow `http` (port 5985).

    ##
    ## httpport -- listening port for the binary protocol (default is 5985)
    ##
    httpport=5985

    ##
    ## httpsport -- listening port for the binary protocol (default is 5986)
    ##
    httpsport=5986

> Note: Save changes to the file. If you forgot to use `sudo` do it again and make sure change took.

## Restart `omid` service
This is required after editing the config file.

    systemctl restart omid

## WinRM Client configuration, Windows
Now, back to your Windows client/laptop you are working from.
Before we can access anything via WinRM, we should run `winrm quickconfig`, if needed.

    winrm quickconfig

## List WinRM TrustedHosts, Windows

    $trusted = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
    $trusted

## Set WinRM TrustedHosts, Windows
When you perform a set command, it overwrites the previous settings, if any.
If you had 3 entries, and then you add 1, you will only have 1 entry.
Since it is a full overwrite, we add the entire array as one value.

    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*.lab.local,linux01,linux02"

> Note: Adjust names to reflect your dsc lab environment

## Using IP Address
If having issues with setting up access with WSMan, you can allow the entire `10.*` subnet (one of 3 private networks outlined in `RFC1918`). If doing this you will need to connect to your device by IP address, at least until configured further in later steps of your deployment, if any.

    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.*"

## Optional - Create DNS A Record
For your linux nodes, you may want to add a static DNS entry in the lab.local domain (not shown).

    mstsc /v:dc01

## Handle your client dns
If needed, confirm you are pointing to the lab domain controllers for dns

    ncpa.cpl

## Optional - Ping or `Test-Connection`
Confirm you can ping the remote linux node.

    C:\>ping linux01

    Pinging linux01.lab.local [10.205.1.157] with 32 bytes of data:
    Reply from 10.205.1.157: bytes=32 time<1ms TTL=64
    Reply from 10.205.1.157: bytes=32 time<1ms TTL=64
    Reply from 10.205.1.157: bytes=32 time<1ms TTL=64
    Reply from 10.205.1.157: bytes=32 time<1ms TTL=64

## Optional - Learn about Ubuntu `ufw` firewall
This is a great guide, so please review the techniques. I use this for everything, including how to locate the configuration and turn off `IPV6` rules.

    https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-16-04

## Configure Ubuntu `ufw` Firewall
Now that we are masters of the `ufw` firewall from reading the guide above, we can get the `omi` ports added to the firewall. Below we reset `ufw` to default and then build it up for our purposes.

> Tip: Don't go doing this on a production server, but for a fresh build we are okay. Your connection via ssh will not be dropped.

    sudo apt-get install ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 5985
    sudo ufw allow 5986
    sudo ufw enable
    
## Show Ubuntu Firewall Entries

    sudo ufw status verbose

## Test port connectivity with `telnet`
If needed, first install the `telnet-client` Windows Feature on your Windows client machine. Then use `telnet` to confirm that the desired port of `5985` (http) or `5986` (https) is open on the target Linux node.

    telnet 10.205.1.157 5986

> Tip: To exit a telnet session on windows type `]`, then type `q`, then press `<enter>`.

## Set local WinRM client to `AllowUnencrypted`
We can optionally set our client to allow unencrypted traffic by setting `AllowUnencrypted` to a value of `$true`. This is kind of needed for `http` access to the remote node.

    Set-Item -Path WSMan:\localhost\Client\AllowUnencrypted -Value $true

## Get WinRM AllowUnencrypted

    Get-Item -Path WSMan:\localhost\Client\AllowUnencrypted

> Note: Remember to set this back when done testing. The scope of this change is limited to your client, but it is global for all WinRM connections.

## Test CIM Connectivity from Windows to Linux
This step uses PowerShell on your Windows client.
We use `Test-WSMan` to vet initial connectivity problems.

    ## Step 1. Launch Powershell from your client
    ## Locate the PowerShell icon and right-click run as Administrator (UAC)

    ## Step 2. Paste into powershell, you will be prompted for guest login.
    $user = 'mike'
    $creds = Get-Credential $user
    Test-WSMan -ComputerName "linux01.lab.local" -Credential $creds -Authentication Basic

    ## example output
    soap                             : http://www.w3.org/2003/05/soap-envelope
    wsmid                            : http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd
    lang                             :
    ProtocolVersion                  : http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd
    ProductVendor                    : Open Management Infrastructure
    ProductVersion                   : 1.1.0-0
    SecurityProfiles                 : SecurityProfiles
    Capability_FaultIncludesCIMError : Capability_FaultIncludesCIMError

## Create cim session
Here, we create a variable for a new CIM session called `$cim`.
You can later use the variable to control the Linux device with DSC.
For now, we are just creating the variables and testing connections.

    #If you already have the $user and $cred variables, just run the $cim line.
    $user = 'mike'
    $creds = Get-Credential $user
    $cim = New-CimSession -ComputerName "linux01.lab.local" -Credential $creds -Authentication Basic

## Show cim session
Show the contents of the `$cim` variable.

    $cim
    Id           : 1
    Name         : CimSession1
    InstanceId   : 75559506-7020-4444-9bac-3eba07f093ed
    ComputerName : linux01.lab.local
    Protocol     : WSMAN

> Note: Observe that you cannot connect after running the next step. You might practice turning the `AllowUnencrypted` on and off.

## Set local WinRM client back to `AllowUnencrypted` value of `$false`
Now that testing is done, we can consider setting `AllowUnencrypted` back to `$false` (the default).

    Set-Item -Path WSMan:\localhost\Client\AllowUnencrypted -Value $false

## Summary
In this write-up we prepared a remote Linux node (Ubuntu 16.04) and got it ready for dsc. We reviewed some secure and insecure techniques to interact with the remote Linux node via WinRM (with `http` and `https`). Now you can configure the LCM or start adding some dsc resources (not shown). Another interesting topic to pursue would be working with self-signed certificates on Linux, though that is not handled here.

## Next, we manage CentOS 7 with omi and dsc
Copy/paste the following into PowerShell to open the next demo.

    code "C:\DSC_LABS\docs\Demo 22 - How to prepare CentOS 7 Linux for DSC.md"


> Note: In the appendix, some other install techniques are shown. The recommendation is to use the supported packages (i.e. omi 1.1.0) shown above, not the latest versions (i.e. omi 1.6.0) shown later in the appendix.

#############
## APPENDIX 
#############

## Optional - Install latest omi
This example shows the latest available omi, version 1.0.6, at the time of this writing.
Please note that this may not be supported by dsc. Check the documentation to determine supported versions of omi. Currently, only version 1.0.1 of omi is supported for dsc. Below, we install version 1.6.0.

    wget https://github.com/Microsoft/omi/releases/download/v1.6.0-0/omi-1.6.0-0.ssl_100.ulinux.x64.deb
    sudo dpkg -i ./omi-1.6.0-0.ssl_100.ulinux.x64.deb

## Optional - Install PowerShell on Ubuntu 16.04
Here we add the microsoft repository. Then, we install `powershell`.

    # add the ms repo by using dpkg, then later we can use apt.
    wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb

    # check for updates
    sudo apt-get update

    # perform the install
    sudo apt -y install powershell

####################
## MORE EXAMPLES
####################

## Plain text example - Using winrm omi

    winrm enumerate http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/OMI_Identify?__cimnamespace=root/omi `
    -r:http://linux01.lab.local:5985 `
    -auth:Basic `
    -u:mike `
    -p:"P@ssword01" `
    -skipcncheck `
    -skipcacheck `
    -encoding:utf-8 `
    -unencrypted

## Slightly more secure approach

    $user = 'mike'
    $node = 'linux01.lab.local'
    $SecurePass = ConvertTo-SecureString -String (Read-Host "Enter linux password for $user") -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential $user, $SecurePass
    $Opt = New-CimSessionOption -UseSsl -SkipCACheck -SkipCNCheck -SkipRevocationCheck

    $Session = New-CimSession `
    -Credential $Cred `
    -ComputerName $node `
    -Port 5986 `
    -Authentication basic `
    -SessionOption $Opt


-end-

## Looking for the CentOS 7 How To document?
Copy/paste the following into PowerShell.

    code "C:\DSC_LABS\docs\Demo 22 - How to prepare CentOS 7 Linux for DSC.md"
