#Requires -Version 3

Function New-LabEsxIso {

  <#

      .SYNOPSIS
        Creates a bootable VMware ESXi ISO for lab.local using kickstart scripted installation.

      .DESCRIPTION
        Creates a bootable VMware ESXi ISO for lab.local using kickstart scripted installation.

      .NOTES
        Script:        New-LabEsxIso.ps1
        Author:        Mike Nisk
        Prior Art:     Based on previous work by Roniva Brown.
        Requires:      CDR-Tools   https://sourceforge.net/projects/cdrtoolswin/files/1.0/Binaries/
        Requires:      dos2unix    https://sourceforge.net/projects/dos2unix/files/dos2unix/
        Requires:      The latest or specified version of ESXi ISO extracted into a folder (or zip download extracted).

  #>

  [cmdletbinding(DefaultParameterSetName='ByPassword')]
  param (

    #String. The name of the new ESXi host to deploy.
    [string]$Name = 'esx01.lab.local',

    #String. IP Address for the new ESXi host.
    [string]$IPAddress = "10.205.1.10",

    #String. Subnet Mask for the new ESXi host.
    [string]$SubnetMask = '255.0.0.0',
    
    #String. Gateway for the new ESXi host.
    [string]$Gateway = '10.205.1.1',

    #String. One or more DNS Server IP Addresses. Can be a string or array of strings. If you need a public DNS you can try '8.8.8.8'.
    [string[]]$DNSServer = @("10.203.1.40","10.205.1.151","10.205.1.152"),
 
    #String. Path to uncompressed ESXi binaries (uncompressed ESXi ISO or uncompressed ESXi zip). This should be a folder name with no trailing backslash.
    [ValidateScript({Test-Path $_})]
    [string]$SourcePath = "$env:USERPROFILE\Downloads\VMware-VMvisor-Installer-6.7.0.update01-10302608.x86_64",

    #String. Path to output ISO files. If this path does not exist we create it.
    [string]$OutputPath = "c:\esxisos",

    #String. The plaintext password for root to create on the new ESXi host. Alternatively, see the IsCryptedPassword parameter.
    [Parameter(ParameterSetName='ByPassword')]
    [string]$Password = 'VMware123!!',

    #String. Optionally, provide the plaintext version of the root encrypted password. You must escape any special characters.
    [Parameter(ParameterSetName='ByCryptedPassword')]
    [string]$IsCryptedPassword,

    #String. Optionally, choose between 'Install' or 'Upgrade'. The default is 'Install'. 
    [ValidateSet('Install','Upgrade')]
    [string]$InstallerType = 'Install',

    #switch. Optionally, show the kickstart contents before creating the ISO.
    [Alias('ShowKS')]
    [switch]$ShowKickStart,

    #String. The path to the dos2unix binaries.
    [string]$Dos2UnixPath = "$env:USERPROFILE\Downloads\dos2unix-7.4.0-win64\bin\dos2unix.exe",

    #String. The dos 8.3 path to the CDRTools binary "mkisofs". The default is the typical location already in short format.
    [string]$mkisofsPath = "c:\Progra~2\cdrtools\mkisofs.exe",

    #String. Optional Description added to kickstart for the node.
    [string]$Description = 'Nested Esxi 6.7',

    #String. Optional Project name added to kickstart for the node.
    [string]$Project = 'DSC LABS'
  
  )

  Process {

    #Handle DNS
    $strDns = $DNSServer -join ','

    ## Announce path to the dos2unix utility
    Write-Verbose -Message ('Using dos2unix binary path of {0}' -f $Dos2UnixPath)
    
    ## Handle output folder for ISO files
    [bool]$outpathExists = Test-Path $OutputPath -ErrorAction Ignore
    If($null -eq $outpathExists -or $outpathExists -eq $false){
        
        try{
            New-Item -ItemType Directory -Path $OutputPath -ErrorAction Stop
            Write-Verbose -Message ('Created output directory {0}' -f $OutputPath)
        }
        catch{
            Write-Warning -Message ('Problem creating output directory {0}' -f $OutputPath)
            throw $Error[0]
        }
    }

    ################################
    ## No need to edit beyond here
    ################################

    ## ISOLINUX.CFG Creation
    Write-Verbose -Message "Creating base ISOLINUX.CFG file"

    ## Specify the path for the isolinux.cfg file to be created
    $isolinuxCfg = "$SourcePath\ISOLINUX.CFG"

    ## Remove existing isolinux.cfg file, if present
    [bool]$existsIsolinuxCfg = Test-Path $isolinuxCfg -ErrorAction Ignore
    if($existsIsolinuxCfg) {Remove-Item $isolinuxCfg -Force -WarningAction Ignore -ErrorAction Stop}

    ## base isolinux.cfg file
    Write-Output -InputObject "DEFAULT menu.c32" | Out-File -en utf8 $isolinuxCfg
    Write-Output -InputObject "MENU TITLE $Project $Description" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "NOHALT 1" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "PROMPT 0" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "TIMEOUT 300" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "LABEL hddboot" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "  LOCALBOOT 0x80" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "  MENU LABEL ^Boot from local disk" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "MENU SEPARATOR" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "LABEL esxiInstaller" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "  KERNEL mboot.c32" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "  APPEND -c boot.cfg" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "  MENU LABEL $Description ^Interactive Installer" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "MENU SEPARATOR" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "LABEL - " | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "  MENU LABEL $Project Scripted Install" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "  MENU DISABLE" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $isolinuxCfg

    ## Populate menu items into the isolinux.cfg file
    Write-Verbose -Message 'Adding menu items to ISOLINUX.CFG'
    Write-Output -InputObject "  LABEL $Name" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "    KERNEL mboot.c32" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "    APPEND -c boot.cfg ks=cdrom:/CFGFILES/KS.CFG" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "    MENU LABEL Deploy $Description on $Name" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject "    MENU INDENT 1" | Out-File -en utf8 -append $isolinuxCfg
    Write-Output -InputObject ""  | Out-File -en utf8 -append $isolinuxCfg
  
    ## Convert the ISOLINUX.CFG file into Unix format
    $ICparameters = "-o $isolinuxCfg"
    Start-Process $Dos2UnixPath $ICparameters -NoNewWindow -Wait

    ## Remove existing kickstart .cfg files, if needed.
    $allKsCfg = "$SourcePath\CFGFILES\KS*"
    $checkKsCfg = Test-Path $allKsCfg -ErrorAction Ignore 
    if ($checkKsCfg -eq $true) {Remove-Item $allKsCfg}

    ## Handle CFGFILES directory
    $pathExists = Test-Path $SourcePath\CFGFILES -ErrorAction Ignore
    If($pathExists){
        Write-Verbose -Message "Testing path to CFGFILES (ok)"
    }
    Else {
        Write-Warning -Message "Missing the CFGFILES directory"
        Write-Verbose -Message "Creating the required directory"
        Try {
            New-Item -ItemType Directory -Path $SourcePath\CFGFILES -ErrorAction Stop -Verbose
        }
        Catch {
            Write-Warning -Message ('{0}' -f $Error[0])
            throw "Problem creating CFGFILES directory!"
        }
    }

    ## Remove BOOT.CAT, if it exists.
    If(Test-Path $SourcePath\BOOT.CAT){
        Write-Verbose -Message "Removing BOOT.CAT file from source image"
        Try {
            Remove-Item -Path $SourcePath\BOOT.CAT -Verbose -Confirm:$false
        }
        Catch {
            Write-Warning -Message "$($_.Exception.Message)"
            throw "Problem removing BOOT.CAT from $($SourcePath) source image.  Please delete manually and try again."
        }
    }

    ## Specify the path for the KS.CFG to be created
    $ksCfg = "$SourcePath\CFGFILES\KS.CFG"
    Write-Verbose -Message ('Populating kickstart at {0}' -f $ksCfg)
      
    ## Handle kickstart eula for ESXi
    Write-Output -InputObject "#	New `"dryrun`" flag to test kickstart" | Out-File -en utf8 $ksCfg
    Write-Output -InputObject "# dryrun" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "# Accept the ESXi License Agreement" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "accepteula" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
    
    ## Handle install vs. upgrade (default is install)
    switch($InstallerType){
        Install {
            Write-Output -InputObject "# Removes all partitions on the first disk and overwrites existing VMFS partition" | Out-File -en utf8 -append $ksCfg
            Write-Output -InputObject "clearpart --firstdisk --overwritevmfs" | Out-File -en utf8 -append $ksCfg
            Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
            Write-Output -InputObject "# Specifies the type of installation." | Out-File -en utf8 -append $ksCfg
            Write-Output -InputObject "install --firstdisk --overwritevmfs" | Out-File -en utf8 -append $ksCfg
            Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
        }
        Upgrade {
            Write-Output -InputObject "# Specifies the type of installation" | Out-File -en utf8 -append $ksCfg
            Write-Output -InputObject "upgrade --firstdisk --preservevmfs" | Out-File -en utf8 -append $ksCfg
            Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
        }
    }
  
    ## Handle reboot options
    Write-Output -InputObject "# Tell the installer to automatically reboot after the install is complete" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "reboot" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
    
    ## Handle root password
    Write-Output -InputObject "# Configure the root Password (can be optionally encrypted with --iscrypted)" | Out-File -en utf8 -append $ksCfg
    If($Password){
        Write-Output -InputObject "rootpw $Password" | Out-File -en utf8 -append $ksCfg
    }
    Elseif($IsCryptedPassword){
        Write-Output -InputObject "rootpw --iscrypted $IsCryptedPassword" | Out-File -en utf8 -append $ksCfg
    }
    Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
  
    ## networking info
    Write-Output -InputObject "# Configure Network" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "network --bootproto=static --device=vmnic0 --ip=$IPAddress --gateway=$Gateway --nameserver=$strDns --netmask=$SubnetMask --hostname=$Name" | Out-File -en utf8 -append $ksCfg
    
    ## First boot
    Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "# Firstboot" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "%firstboot --interpreter=busybox" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg

    ## Handle ssh
    Write-Output -InputObject "# Enable and start SSH Access" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "/usr/bin/vim-cmd hostsvc/enable_ssh" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "/usr/bin/vim-cmd hostsvc/start_ssh" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "# Enable and start Shell Access" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "/usr/bin/vim-cmd hostsvc/enable_esx_shell" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "/usr/bin/vim-cmd hostsvc/start_esx_shell" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "# Disable configuration error from enabling ssh and shell access" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "/usr/bin/vim-cmd hostsvc/advopt/update UserVars.SuppressShellWarning long 1" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg

    ## sync and reboot
    Write-Output -InputObject "# sync bootbanks" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "/bin/sync" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "/bin/sync" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "/bin/auto-backup.sh" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "/bin/auto-backup.sh" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "# Reboot the server" | Out-File -en utf8 -append $ksCfg
    Write-Output -InputObject "reboot" | Out-File -en utf8 -append $ksCfg

    If($ShowKickStart){
        Write-Output -InputObject 'Kickstart Config:'
        Get-Content $ksCfg | Out-String
        Write-Output ''
        Start-Sleep -Seconds 5
    }
  
    # Convert the KS.CFG file into Unix format
    $KCparameters = "-o $ksCfg"
    Start-Process $Dos2UnixPath $KCparameters -NoNewWindow -Wait -Verbose
    
    $strShortName = $Name -split '\.' | Select-Object -First 1
    $isoName = ('{0}.iso' -f $strShortName)
    Write-Verbose -Message ('Creating ISO: {0}' -f $isoName)
    $parameters = "-relaxed-filenames -J -R -o $OutputPath\$isoName -b ISOLINUX.BIN -c BOOT.CAT -no-emul-boot -boot-load-size 4 -boot-info-table $SourcePath"
    
    try{
        $null = Start-Process $mkisofsPath $parameters -Wait -ErrorAction Stop
        Write-Verbose ('You may now copy {0} from {1}' -f $isoName, $OutputPath)
    }
    catch{
        Write-Warning -Message 'Problem creating ISO!'
        Write-Error -Message $Error[0].exception.Message
    }
  }
}