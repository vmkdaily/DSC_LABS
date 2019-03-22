#Requires -Version 3

Function Invoke-OvfTool {

  <#
        .DESCRIPTION
          Deploy a VMware vCenter Server using Microsoft PowerShell. In the vCenter Server ISO, there is a complete folder-based layout of tools
          that support the deployment of OVA. The binary is known as OVFTool and is available for many devices. Here we focus on Windows as our
          client that we will deploy from.
          
          To use this kit, download and extract the vCenter Server ISO to a directory, using a POSIX compliant unzipper such as 7zip.
          By default, we expect it to be in the Downloads folder (i.e. "$env:USERPROFILE\Downloads"). However, you can also populate the Path
          parameter with the location to the uncompressed bits.

          Note: You may see mention of 32bit because that is how OVFTOOL works. However, all binaries support 64 bit Windows.

          Important: Currently a utility called dos2unix.exe is also required to get the JSON file in the proper unix format.
          Much like the VC binaries, dos2unix.exe is a folder-based runtime, so there is no need to install. Simply download it
          and populate the Dos2UnixPath parameter with the full path. By default we expect it to be in "$env:USERPROFILE\Downloads",
          like everything else.

          Download 7zip:
          https://www.7-zip.org/download.html
          
          Download dos2unix:
          https://sourceforge.net/projects/dos2unix/files/dos2unix/

          Download vCenter Server (requires login; Create account if needed):
          https://my.vmware.com/group/vmware/details?downloadGroup=VC670B&productId=742&rPId=24515

        .NOTES
          Name:         Invoke-OvfTool.ps1
          Author:       Mike Nisk
          Dependencies: Extracted vCenter Server installation ISO for the latest vCenter Server 6.7
          Dependencies: dos2unix.exe (not provided by VMware). This is needed to convert the OutputJson file into unix filetype
          Dependencies: Account on ESXi that can be used for login and deployment. The recommendation is to create an account for
                        the duration of the deployment and then remove it. In the examples, we refer to a ficticious account called
                        ovauser which you can manually create on ESXi as a local user. After the OVA is deployed you can remove the user.
                        Creating and removing ESXi users is optional and is not handled by the script herein. Alternatively, just use root.
	
        .PARAMETER Path
          String. The path to the win32 directory of the extracted vCenter Server installation ISO.
          By default we expect "$env:USERPROFILE\Downloads\VMware-VCSA-all-6.7.0-11726888\vcsa-cli-installer\win32"

        .PARAMETER OvfConfig
          PSObject. A hashtable containing the deployment options for a new vCenter Server appliance. See the help for details on creating and using a variable for this purpose.

        .PARAMETER Interactive
          Switch. Optionally be prompted for all required values to deploy the vCenter OVA. Not recommended. Instead, use the OvfConfig parameter. See the help for details.

        .PARAMETER TemplatePath
          String. Path to the JSON file to model after. This would be the example file provided by VMware or one that you customized previously to become your master.
          We assume no previous work was done and we use the template from VMware and modify as needed.
          The default is "$env:USERPROFILE\Downloads\VMware-VCSA-all-6.7.0-11726888\vcsa-cli-installer\templates\install\embedded_vCSA_on_ESXi.json".

        .PARAMETER OutputPath
          String. The full path to the JSON configuration file to create. If the file exists, we overwrite it.
          The default is "$env:Temp\myConfig.JSON".

        .PARAMETER JsonPath
          String. The full path to the JSON configuration file to use when deploying a new vCenter appliance.

        .PARAMETER Mode
          String. Tab complete through options of Design, Test, Deploy or LogView.
    
        .PARAMETER Description
          String. The name of the site or other friendly identifier for this job.

        .PARAMETER Depth
          Integer. Optionally, enter an integer value denoting how many objects to support when importing a JSON template.
          The default is '10', which is up from the Microsoft default Depth of '2'. The maximum is 100.  The Depth must be
          higher than the number of items in the JSON template that we read in.
    
        .EXAMPLE
        #Paste this into PowerShell

        $OvfConfig = @{
          esxHostName            = "esx01.lab.local"
          esxUserName            = "root"
          esxPassword            = "VMware123!!"
          esxPortGroup           = "VM Network"
          esxDatastore           = "datastore1"
          ThinProvisioned        = $true
          DeploymentSize         = "tiny"
          DisplayName            = "vcsa01"
          IpFamily               = "ipv4"
          IpMode                 = "static"
          Ip                     = "10.205.1.11"
          FQDN                   = "vcsa01.lab.local"
          Dns                    = @("10.1.2.3","10.2.3.4","8.8.8.8") #testing as array (formerly single string)
          SubnetLength           = "24"
          Gateway                = "10.205.1.1"
          VcRootPassword         = "VMware123!!!"
          VcNtp                  = @("0.pool.ntp.org","1.pool.ntp.org","2.pool.ntp.org") #testing as array (formerly single string)
          SshEnabled             = $true
          ssoPassword            = "VMware123!!!"
          ssoDomainName          = "vsphere.local"
          ceipEnabled            = $false
        }

	Note: Passwords must be complex.
	
        This example created a PowerShell object to hold the desired deployment options.
        Please note that some values are case sensitive (i.e. datastore).
        
        .EXAMPLE
        $Json = Invoke-OvfTool -OvfConfig $OvfConfig -Mode Design
        $Json  | fl *  #observe output and get the path
	Invoke-OvfTool -OvfConfig $OvfConfig -Mode Deploy -JsonPath <path-to-your-json-file>

        This example creates a variable pointing to a default VMware JSON configuration.
        We then overlay our settings at deploy time using the $OvfConfig variable we created previously.
        This results in a customized vCenter Appliance.

        .EXAMPLE
        $result = Invoke-OvfTool -Mode LogView -LogDir "c:\Temp\workflow_1525282021542"
        $result            # returns brief overview of each log file
        $result |fl *      # returns all detail

        This example shows how to review logs from previous runs. If you do not specify Logir parameter, we search for all JSON files in the default LogDir location.

        ABOUT WINDOWS CLIENT REQUIREMENTS

          It is recommended that you have already run the test script that VMware includes to
          check for the required 32bit C++ runtime package:

            vcsa-cli-installer\win32\check_windows_vc_redist.bat

          If the above script indicates that you are out of date, the minimum required version
          is included on the vCenter Server ISO. You can also download the latest version directly
          from Microsoft.com.


        ABOUT SSL CERTIFICATE HANDLING

          When using vcsa-deploy.exe (which we call in the background), one can optionally set a preference at runtime
          to determine how invalid certificates are handled. The "--no-esx-ssl-verify" is deprecated and "--no-ssl-certificate-verification"
          is used instead.

        ABOUT UNICODE ESCAPE (u0027)
    
          When dealing with JSON files in PowerShell you may notice the characters u0027 accidentally placed throughout your text content.
          This is a known issue and we handle it. We prevent these unicode escape characters (u0027) from being injected into the outputted
          JSON file by adjusting the Depth parameter of ConvertTo-Json.
          
          Over time, and depending on the deployment options required, you may need to adjust the Depth to suit your needs.
          By keeping the default depth of 2, you will notice 'u0027' throughout your JSON configuration file.

          To avoid this, we attempt to increase the Depth to something greater than the total count of sections VMware currently provides in the JSON template.
          The Microsoft supported maximum for PowerShell 5.1 is a Depth of 100, or 100 items that can be ported in as objects. For our purposes, in doing
          an ESXi deployment of an embedded VC, we only need a Depth of '4' or '5'. However, you can safely make it something like 50 or 99 without issue.

          More about unicode escape:
          http://www.azurefieldnotes.com/2017/05/02/replacefix-unicode-characters-created-by-convertto-json-in-powershell-for-arm-templates/

    
        ABOUT UTF8 REQUIREMENTS (and dos2unix.exe)
    
          When saving the JSON file with PowerShell's Out-File cmdlet, we encode using utf8 and then run dos2unix.exe (with the -o parameter)
          to ensure that the file is encoded as unix utf8. If you skip this final step of running dos2unix, the VMware pre-deployment tests may fail.
    
    #>

  [CmdletBinding()]
  Param(
		
    #String. The path to the win32 directory of the extracted vCenter Server installation ISO.
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path = "$env:USERPROFILE\Downloads\VMware-VCSA-all-6.7.0-11726888\vcsa-cli-installer\win32",
	
    #PSObject. A hashtable containing the deployment options for a new vCenter Server appliance.
    [PSObject]$OvfConfig,
		
    #String. Path to the JSON file to model after. This would be the example file provided by VMware or one that you have customized.
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$TemplatePath = "$env:USERPROFILE\Downloads\VMware-VCSA-all-6.7.0-11726888\vcsa-cli-installer\templates\install\embedded_vCSA_on_ESXi.json",

    #String. The full path to the JSON configuration file to create. This is used in Design Mode to create a JSON file on disk containing all customizations for this deployment.
    [string]$OutputPath = "$env:Temp\myConfig.JSON",
  
    #String. The Config File to use when deploying a new vCenter Server appliance.
    [ValidateScript({Test-Path -PathType Leaf $_})]
    [string]$JsonPath,
	
    #String. Tab complete through options of Design, Test, Deploy or LogView.
    [ValidateSet('Design','Test','Deploy','LogView')]
    [string]$Mode,

    #String. Dos2Unix binary location. Adjust as needed and download if you do not have it.
    [string]$Dos2UnixPath = "$env:USERPROFILE\Downloads\dos2unix-7.4.0-win64\bin\dos2unix.exe",
    
    #Switch. Optionally, activate to skip all dos2unix requirements and file conversion steps.
    [switch]$SkipDos2Unix,

    #String. The directory to write or read logs related to ovftool. This is not PowerShell transcript logging, this is purely deployment related and the resuling output paths are long, so keep this path short for best results.
    [string]$LogDir = $env:Temp,
  
    #String. The name of the site or other friendly identifier for this job.
    [string]$Description,
  
    #Integer. The Depth is an integer value denoting how many objects to support when importing a JSON template. Max is 100, default is here is 10.
    [ValidateRange(1,100)]
    [int]$Depth = '10'
  )

  Process {
  
    ## Path to vcsa-deploy.exe binary
    $vcsa_deploy = "$Path\vcsa-deploy.exe" 
    
    switch($Mode){
      Design{

        If(-Not($SkipDos2Unix)){
          try{
            Test-Path -Path $Dos2unixPath -PathType Leaf -ErrorAction Stop
          }
          catch{
            throw 'Dos2Unix is required!'
          }
        }
  
        ## JSON to Object
        $obj_Json_Template = (Get-Content -Raw $TemplatePath) -join "`n" | ConvertFrom-Json

        ## New variable to hold our options
        $myOpts = $obj_Json_Template

        ## If user did not populate the OvaConfig parameter
        If(-Not($OvfConfig)){

          Write-Warning -Message 'OvfConfig parameter was not populated!'
          Write-Output -InputObject 'Enter the details below (~20 items), or press CTRL + C to exit.'
          Write-Output -InputObject ''
    
          ## Build the object
          $OvfConfig = New-Object -TypeName PSObject -Property @{

            esxHostName       =  Read-Host -Prompt 'esxHostName'
            esxUserName       =  Read-Host -Prompt 'esxUserName'
            esxPassword       =  Read-Host -Prompt 'esxPassword'
            esxPortGroup      =  Read-Host -Prompt 'esxPortGroup'
            esxDatastore      =  Read-Host -Prompt 'esxDatastore'
            ThinProvisioned   = (Read-Host -Prompt 'ThinProvisioned (true/false)').ToLower()
            DeploymentSize    =  Read-Host -Prompt 'DeploymentSize (i.e. tiny,small,etc.)'
            DisplayName       =  Read-Host -Prompt 'DisplayName'
            IpFamily          =  Read-Host -Prompt 'IpFamily (i.e. ipv4)'
            IpMode            =  Read-Host -Prompt 'IpMode (i.e static)'
            Ip                =  Read-Host -Prompt 'IP Address'
            Dns               =  Read-Host -Prompt 'Dns Address'
            SubnetLength      =  Read-Host -Prompt 'Subnet Length (i.e. 16, 24, etc.)'
            Gateway           =  Read-Host -Prompt 'Gateway'
            FQDN              =  Read-Host -Prompt 'FQDN'
            VcRootPassword    =  Read-Host -Prompt 'VcRootPassword'
            VcNtp             =  Read-Host -Prompt 'VcNtp'
            SshEnabled        = (Read-Host -Prompt 'SSH Enabled (true/false)').ToLower()
            ssoPassword       =  Read-Host -Prompt 'ssoPassword'
            ssoDomainName     =  Read-Host -Prompt 'ssoDomainName'
            ceipEnabled       = (Read-Host -Prompt 'ceipEnabled (true/false)').ToLower()
          }
        }
      
        #region Ovf Configuration
        If($OvfConfig){

          ## Comments
          If($Description){
            $myOpts.__comments                            = "Custom deployment template for $($Description) using embedded VC deployment type"
          }
          Else{
            $myOpts.__comments                            = "Custom deployment template using embedded VC deployment type"
          }
          $myOpts.new_vcsa.appliance.__comments           = "appliance options"
          $myOpts.ceip.description.__comments             = "ceip options"
    
          ## Options esxi
          $myOpts.new_vcsa.esxi.hostname                  = $OvfConfig.esxHostName
          $myOpts.new_vcsa.esxi.username                  = $OvfConfig.esxUserName
          $myOpts.new_vcsa.esxi.password                  = $OvfConfig.esxPassword
          $myOpts.new_vcsa.esxi.deployment_network        = $OvfConfig.esxPortGroup
          $myOpts.new_vcsa.esxi.datastore                 = $OvfConfig.esxDatastore

          ## Options appliance
          $myOpts.new_vcsa.appliance.thin_disk_mode       = $OvfConfig.ThinProvisioned
          $myOpts.new_vcsa.appliance.deployment_option    = $OvfConfig.DeploymentSize
          $myOpts.new_vcsa.appliance.name                 = $OvfConfig.DisplayName

          ## Options network
          $myOpts.new_vcsa.network.ip_family              = $OvfConfig.IpFamily
          $myOpts.new_vcsa.network.mode                   = $OvfConfig.IpMode
          $myOpts.new_vcsa.network.ip                     = $OvfConfig.IP
          $myOpts.new_vcsa.network.dns_servers            = $OvfConfig.Dns
          $myOpts.new_vcsa.network.prefix                 = $OvfConfig.SubnetLength
          $myOpts.new_vcsa.network.gateway                = $OvfConfig.Gateway
          $myOpts.new_vcsa.network.system_name            = $OvfConfig.FQDN

          ## Options os
          $myOpts.new_vcsa.os.password                    = $OvfConfig.VcRootPassword
          $myOpts.new_vcsa.os.ntp_servers                 = $OvfConfig.VcNtp
          $myOpts.new_vcsa.os.ssh_enable                  = $OvfConfig.SshEnabled

          ## Options sso
          $myOpts.new_vcsa.sso.password                   = $OvfConfig.ssoPassword
          $myOpts.new_vcsa.sso.domain_name                = $OvfConfig.ssoDomainName

          ## Options ceip
          $myOpts.ceip.settings.ceip_enabled              = $OvfConfig.ceipEnabled
        } #End If
        #endregion
  
        ## Output to file
        Write-Verbose -Message ('Saving {0} to disk' -f $OutputPath)
        $myOpts | Select-Object -Property * | ConvertTo-Json -Depth $Depth | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File -Encoding utf8 $OutputPath

        ## Convert to unix format
        $wrappedCmd = "-o $OutputPath"
        Write-Verbose -Message ('Converting {0} to unix format' -f $OutputPath)
        Start-Process $Dos2unixPath $wrappedCmd -NoNewWindow -Wait
        
        ## Output FullName
        try{
            $JsonFile = Get-ChildItem $OutputPath -ErrorAction Stop
            return ($JsonFile | Select-Object -ExpandProperty FullName)
        }
        catch{
            Write-Error -Message $Error[0].exception.Message
        }
      }
      Test{
        Write-Verbose -Message ('Testing JSON file {0}' -f $JsonPath)
        $result = Start-Process $vcsa_deploy "install $JsonPath --accept-eula --precheck-only --log-dir $LogDir" -NoNewWindow -Wait
        return $result
      }
      Deploy{
    
        ## Deploy OVA
        Write-Verbose -Message 'Deploying vCenter Server OVA!'
        try{
          $result = Start-Process $vcsa_deploy "install $JsonPath --accept-eula --no-ssl-certificate-verification --log-dir $LogDir" -NoNewWindow -Wait
        }
        catch{
          Write-Warning -Message 'Problem deploying OVA!'
          Write-Error -Message ('{0}' -f $_.Exception.Message)
        }
        return $result
      }
      LogView{
        $result = Get-ChildItem $logDir -Recurse -Include *.JSON | ForEach-Object {$file = $_; "Processing: $file"; (Get-Content $file) -join "`n" | ConvertFrom-Json}
        return $result
      }
    } #End Switch
  } #End Process
}
