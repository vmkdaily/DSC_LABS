## How to prepare CentOS 7 Linux for DSC
This document is a guide to get Desired State Configuration (DSC) running on CentOS 7 Linux.

Note: See the official project page to find other supported distributions.

## PowerShell DSC for Linux
Visit the official github project page for the latest details

    https://github.com/Microsoft/PowerShell-DSC-for-Linux

## Optional create user
Create a user during the GUI install, or create one manually.

    adduser mike

## set the user password

    passwd mike

## Add user to sudo
If you forgot to check the box for "make this user administrator" during the user creation at install time, this command will take care of that.

    usermod -aG wheel mike

## Security profile
If you chose the default profile for servers and desktops, you should now be able to access the node via ssh as your user account.

## Optional packages
For new CentOS 7 systems, the following are popular for basic systems:

    sudo yum install open-vm-tools
    sudo yum install epel-release

## Reboot node
    sudo sync
    sudo sync
    sudo reboot

## Install nano
When the node comes back up, install nano text editor

    sudo yum install nano

## List your existing repos

    ls -lh /etc/yum.repos.d/

## Add the Microsoft repo
This will make `PowerShell` and `omi` installations and updates available from `yum`.

    sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm

## Install PowerShell on Linux
Not required, but desired. Use this especially if building an authoring machine for DSC on Linux.
If you will just use PowerShell from Windows to manage Linux via omi, then you may not need PowerShell on the Linux guest.

    curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
    sudo yum install -y powershell

## Optional - Launch `pwsh` and handle `$PROFILE`
Here we launch PowerShell and create a PowerShell $PROFILE.

    pwsh
    If(-Not(Test-Path $PROFILE)){ New-Item -Type File -Path $PROFILE -Force }
    nano $PROFILE

> Nothing is required in the profile for our purposes; You can just exit, or add desired changes.

## Optional - exit powershell
You can perform all installs and typically shell commands that you would do in Linux from within your `pwsh` session. Just remember that your history will be in powershell and not in the Linux session.

## Optional - Add support to compile `omi`
This is no longer needed, since we do not have to compile (though you can).
For a lightweight image, skip this; Or, for a beefy test machine with all the bits, add it.

    sudo yum groupinstall 'Development Tools'
    sudo yum -y install pam-devel openssl-devel redhat-lsb

> Note: You may not need `redhat-lsb` but we add it anyway since it has been reported to benefit DSC at least in the past. Also notable, is that despite the `redhat` name, this is in fact supported for `CentOS 7`.

## Install Open Management Infrastructure (omi)
Since we have the microsoft repo, and all dependencies, we can simply install the `omi` application from `yum`.

    sudo yum install omi

## Optional - Show service status for `omid`
Because we used `yum` to install `omi`, the app is automatically added to systemd

    sudo systemctl status omid

## Optional - Show the `omi` binaries
Optionally, list the contents of the `omi` binaries directory.

    ls -lh /opt/omi/bin/

## Example output

    $ ls -lh /opt/omi/bin/
    total 3.3M
    lrwxrwxrwx. 1 root root   41 Dec 24 21:59 ConsistencyInvoker -> /opt/microsoft/dsc/bin/ConsistencyInvoker
    -rwxr-xr-x. 1 root root 760K Jul 23 11:09 omiagent
    -rwxr-xr-x. 1 root root 162K Jul 23 11:09 omicli
    -rwxr-xr-x. 1 root root  37K Jul 23 11:09 omiconfigeditor
    -rwxr-xr-x. 1 root root 910K Jul 23 11:09 omiengine
    -rwxr-xr-x. 1 root root 432K Jul 23 11:09 omigen
    -rwxr-xr-x. 1 root root  75K Jul 23 11:09 omireg
    -rwxr-xr-x. 1 root root 919K Jul 23 11:09 omiserver
    -rwxr-xr-x. 1 root root 6.7K Jul 22 19:00 service_control
    drwxr-xr-x. 2 root root  171 Dec 24 21:31 support

## Configure `omid` service
Enter an editor such as `vi` or `nano` to edit the config file.

    sudo nano /etc/opt/omi/conf/omiserver.conf
    
## Example default http port
By default, the configuration looks like the following for http:

    ##
    ## httpport -- listening port for the binary protocol (default is 5985)
    ##
    httpport=0

## Setting a default http port
We can explicitly set to the following:
    ##
    ## httpport -- listening port for the binary protocol (default is 5985)
    ##
    httpport=5985

## Restart the `omid` service

    sudo systemctl restart omid

## Ports
The omi application on Linux serves up a CIM connection (think `WinRM` / `WSMAN`) and uses ports `5985` and `5986` for `http` and `https` respectively (by default).

## Optional - Show client setting for AllowUnencrypted

    Get-Item -Path WSMan:\localhost\Client\AllowUnencrypted

## Optional (not secure) - Set WinRM to AllowUnencrypted
This is optional, but is totally recommended for your lab testing and enjoyment.
If desired, change `AllowUnencrypted` to a value of `$true`

    Set-Item -Path WSMan:\localhost\Client\AllowUnencrypted -Value $true

> Note: Remember to set this back when done testing. The scope of this change is limited to your local client machine, but it is global for all WinRM connections from your local machine.

# Set the omi ports
Show the `omi` service status, configure it, and restart it.

    sudo systemctl status omid
    sudo nano /etc/opt/omi/conf/omiserver.conf
    sudo systemctl restart omid

> Tip: To save in `nano`, press `CTRL + X`, then `y`, then press `<enter>`.

## Configure Firewall on CentOS 7 Linux
If you made it this far, this is where we actually make things work.
Lets allow omi to use `https` on port `5986`.
We can do this by copying an existing rule to get the syntax.

Any `.xml` file listed at `/usr/lib/firewalld/services/` will work fine.
We will use `wbem-https` as the source and copy it to `omid-https.xml`, a derived name we are creating.
Finally, we will edit the file with `nano` to suit our needs and then allow through the firewall.

    sudo cp /usr/lib/firewalld/services/wbem-https.xml /usr/lib/firewalld/services/omid-https.xml
    sudo nano /usr/lib/firewalld/services/omid-https.xml
    sudo firewall-cmd --reload
    sudo firewall-cmd --permanent --zone=public --add-service=omid-http
    sudo firewall-cmd --reload

## Contents of omid.xml
This is an example of the file we just created above. The name of the `.xml` file (leaf with no extension) should match the `short` name.
In this example the file is named `omid-hpps.xml` and the `short` is `omid-https`. The description can be manually updated as well.

    [mike@centos7 bin]$ cat /usr/lib/firewalld/services/omid.xml
    <?xml version="1.0" encoding="utf-8"?>
    <service>
    <short>omid-https</short>
    <description>Custom rule for https connections using omi over port 5986 (CIM)</description>
    <port protocol="tcp" port="5986"/>
    </service>

> Tip: To see all rules, `ls -lh /usr/lib/firewalld/services/`

## Optional - Create an entry for `omid-http` at port `5985`

    sudo cp /usr/lib/firewalld/services/wbem-https.xml /usr/lib/firewalld/services/omid-http.xml
    sudo nano /usr/lib/firewalld/services/omid-http.xml
    sudo firewall-cmd --reload
    sudo firewall-cmd --permanent --zone=public --add-service=omid-https
    sudo firewall-cmd --reload

## WinRM Client configuration, Windows
Windows can be confirmed as good to go by successfully running `winrm quickconfig`

    PS C:\> winrm quickconfig
    WinRM service is already running on this machine.
    WinRM is already set up for remote management on this computer.

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
If having issues with setting up access with WSMan, you can allow the entire `10.*` subnet (one of 3 private networks outlined in `RFC1918`). If doing this you will need to connect to your device by IP address, at least until configured further.

    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.*"

## Test port connectivity with `telnet`
If needed, first install the `telnet-client` Windows Feature on your Windows client machine. Then use `telnet` to confirm that the desired port of `5985` is open on the target Linux node.

    telnet 10.205.1.158 5985

> Tip: To exit a telnet session on windows type `]`, then type `q`, then press `<enter>`.

## Test CIM Connectivity from Windows
First we use `Test-WSMan` to vet initial connectivity problems.
Then we create a variable for the CIM session called `$cimSession`.
You can later use the variable to control the Linux device with DSC.
For now we are just creating the variables and testing connections.

    C:\> $creds = Get-Credential centos
    C:\> Test-WSMan -ComputerName "linux02.lab.local" -Credential $creds -Authentication Basic


    soap                             : http://www.w3.org/2003/05/soap-envelope
    wsmid                            : http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd
    lang                             :
    ProtocolVersion                  : http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd
    ProductVendor                    : Open Management Infrastructure
    ProductVersion                   : 1.5.0-0
    SecurityProfiles                 : SecurityProfiles
    Capability_FaultIncludesCIMError : Capability_FaultIncludesCIMError

    C:\> $cimSession = New-CimSession -ComputerName "linux02.lab.local" -Credential $creds -Authentication Basic
    C:\>
    C:\> $cimSession

    Id           : 4
    Name         : CimSession4
    InstanceId   : b3632bb3-b30f-462d-bd07-bbd5fe791c6a
    ComputerName : linux02.lab.local
    Protocol     : WSMAN


## Install Desired State Configuration (DSC)
Now that we have `omi` up and running, we can proceed with installing DSC (Desired State Configuration). For this, we will install the dsc application from an `rpm` package.

    wget https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_100.x64.rpm
    sudo rpm -Uvh dsc-1.1.1-294.ssl_100.x64.rpm

## List dsc scripts
On Linux, you can list the `dsc` scripts on the system with `ls` or similar.
Here we hop into PowerShell and perform the list with `Get-ChildItem` (a.k.a. `dir`).

    pwsh
    gci /opt/microsoft/dsc/Scripts/ | select name

    Name
    ----
    2.4x-2.5x
    2.6x-2.7x
    3.x
    client.py
    GetDscConfiguration.py
    GetDscLocalConfigurationManager.py
    helperlib.py
    ImportGPGKey.sh
    InstallModule.py
    nxDSCLog.py
    PerformInventory.py
    PerformRequiredConfigurationChecks.py
    protocol.py
    RegenerateInitFiles.py
    Register.py
    RegisterHelper.sh
    RemoveModule.py
    RestoreConfiguration.py
    SetDscLocalConfigurationManager.py
    StartDscConfiguration.py
    StatusReport.sh
    TestDscConfiguration.py
    zipfile2.6.py
    zipfile2.6.pyc

## Optional - Install the `nx` module on Linux
The `nx` module is an official module created by the PowerShell Team.
Here we use `Install-Module` to get the bits from the gallery as usual.
If you want to author and do more advanced stuff with DSC then install this.
For a simple client, or when building a master image, this is not needed.

    Install-Module -Name nx -Scope CurrentUser

## Optional - Windows Client to manage Linux
From a Windows client, you can add support to manage the DSC of Linux devices.
The following command will install the nx module from the Microsoft gallery:

    Install-Module -Name nx

> Note: You can have the `nx` resource on Windows, for example to create configurations and push to remote nodes, but not to consume on Windows directly.

## Optional - Show the nx module contents
From a Windows or Linux client with the nx module installed, we can view the available resources with `Get-DscResource`

    Get-DscResource -Module nx | select name,properties

    Name                Properties
    ----                ----------
    nxArchive           {DestinationPath, SourcePath, Checksum, DependsOn...}
    nxEnvironment       {Name, DependsOn, Ensure, Path...}
    nxFile              {DestinationPath, Checksum, Contents, DependsOn...}
    nxFileLine          {ContainsLine, FilePath, DependsOn, DoesNotContainPattern...}
    nxGroup             {GroupName, DependsOn, Ensure, Members...}
    nxPackage           {Name, Arguments, DependsOn, Ensure...}
    nxScript            {GetScript, SetScript, TestScript, DependsOn...}
    nxService           {Controller, Name, DependsOn, Enabled...}
    nxSshAuthorizedKeys {KeyComment, DependsOn, Ensure, Key...}
    nxUser              {UserName, DependsOn, Description, Disabled...}

> Tip: `gcm -Module nx` will not return any results (expected). Instead, use `Get-DscResource` as shown above.

## Determine if the module is installed
Some time later, you may want to check if a system (Windows or Linux) has the `nx` module installed.
For this we can use `Get-Module -ListAvailable -Name nx`.

    PS /home/mike> Get-Module -ListAvailable -Name nx                                                                                                                                                                                                                                                                Directory: /home/mike/.local/share/powershell/Modules


    ModuleType Version    Name                                PSEdition ExportedCommands
    ---------- -------    ----                                --------- ----------------
    Manifest   1.0        nx                                  Desk

> Note: On some older versions, or if you manually download the bits, you may need to move the `nx` modules to some desired module path. In the above, we trust PowerShell to deliver the bits in a usable location.

## Optional - Manual `nx` Download
If desired, we can clone or otherwise download the bits from the official project page:

    https://github.com/Microsoft/PowerShell-DSC-for-Linux

## Summary
If you followed along, you now have `Open Management Infrastructure` and `PowerShell DSC` running on Linux! We used `yum` to install `PowerShell` and `omi`; Then finally we installed `DSC` on Linux using an `rpm` package. Nothing needs to be compiled from source (though you can). Awesome power unlocked.

## Supporting Links
We use the official microsoft documentation for adding a repo. Check here for updates to the process:

    https://docs.microsoft.com/en-us/windows-server/administration/Linux-Package-Repository-for-Microsoft-Software

Omi Official Project page:

    https://github.com/Microsoft/omi

DSC Resources (check the DSC box and search for cool stuff, they all begin with x for experimental):

    https://www.powershellgallery.com/packages

## Supporting Training

    See pluralsight.com for video training on DSC. However, use the techniques outlined hereinabove instead of installing older versions such as omi 1.0.8.

    Also, see Microsoft Virtual Academy for free DSC training videos (available until end of Jan 2019 or whenever microsoft migrates to their new site).

## APPENDIX
Some additional content and techniques.

## Legacy technique to add repo

    # Install repository configuration
    curl https://packages.microsoft.com/config/rhel/7/prod.repo > ./microsoft-prod.repo
    sudo cp ./microsoft-prod.repo /etc/yum.repos.d/
    
    # Install Microsoft's GPG public key
    curl https://packages.microsoft.com/keys/microsoft.asc > ./microsoft.asc
    sudo rpm --import ./microsoft.asc

## Default test from Windows to Linux (using ssl and no certs)
This example comes from https://docs.microsoft.com/en-us/azure/automation/automation-dsc-onboarding

    $SecurePass = ConvertTo-SecureString -String '<root password>' -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential 'root', $SecurePass
    $Opt = New-CimSessionOption -UseSsl -SkipCACheck -SkipCNCheck -SkipRevocationCheck
    $Session = New-CimSession -Credential $Cred -ComputerName <your Linux machine> -Port 5986 -Authentication basic -SessionOption $Opt
