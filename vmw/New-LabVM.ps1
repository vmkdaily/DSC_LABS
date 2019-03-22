Function New-LabVM {

  <#

      .DESCRIPTION
        Function to deploy lab virtual machines using native PowerCLI cmdlets.

      .NOTES
        Script:    New-LabVM.ps1
        Author:    Mike Nisk
        Prior Art: Based on previous work by Roniva Brown.

    .EXAMPLE
    ise "C:\DSC_LABS\vmw\LAB_OPTIONS.ps1"
    Import-Module "C:\DSC\LABS\vmw\LAB_OPTIONS.ps1"
    New-LabVM @s1

    This example edited the options file (user interaction required unless using defaults); Then the example imported the options, and finally deployed the s1 server.

    .EXAMPLE
    Import-Module "C:\DSC\LABS\vmw\LAB_OPTIONS.ps1"
    New-LabVM @s2

    This example dot sourced the options file and deployed server s2.

    .EXAMPLE
    $jump = @{
      Name             = 'dscjump01'
      GuestCredential  = $credsGOS
      MemoryGB         = 8
      NumCPU           = 2
      Description      = 'Jump Server'
      Template         = 'W2016Std-Template-Master'
      IPAddress        = '10.205.1.150'
      SubnetMask       = '255.0.0.0'
      Gateway          = '10.205.1.1'
      DnsAddress       = '8.8.8.8'
      DnsSuffix        = 'lab.local'
      Folder           = 'DSC LABS'
      PortGroup        = 'VM Network'
      RunOnce          = $RunOnce
      Console          = $true
      Verbose          = $true
    }
    New-LabVM @jump

    This example created a variable to hold some deployment options and then deployed a server named dscjump01.

  #>
  
    [CmdletBinding()]
    Param(
    
      #String. The IP Address or DNS name of the vCenter Server. You must already be connected.
      [string]$Server,

      #String. Optionally, enter the the IP Address or DNS name of the ESXi host to deploy the virtual machine to. This is optional and selected at random if not provided.
      [string]$VMHost,
      
      #String. The name of the virtual machine to deploy. This will be the DisplayName of the virtual machine and the guest name.
      [string]$Name,
      
      #PSCredential. The login for the Windows template. Can be populated by the LAB_OPTIONS file or at runtime.
      [PSCredential]$GuestCredential,
      
      #String. The guest IP Address.
      [string]$IPAddress,
      
      #Integer. The Memory to assign to the virtual machine in GB.
      [int]$MemoryGB,
      
      #Integer. The number of vCPU to assign to the virtual machine.
      [int]$NumCPU,
      
      #String. The name of the site. Used for notes, etc.
      [string]$Site        = 'DSC Labs',
      
      #String. The organization name for os customization specification.
      [string]$OrgName     = 'DSC Labs',
      
      #String. The Full name for the guest os customization specification.
      [string]$FullName    = 'DSC Labs',
      
      #String. Description of the node, such as "Jump Server", "Pull Server", etc.
      [string]$Description = 'Test node',
      
      #String. The name of the vCenter template.
      [string]$Template    = 'W2016Std-Template-Master',
      
      #Integer. The timezone number for the guest. Central is 20; Amsterdam is 110
      [int]$TimeZone       = '20',
      
      #String. The subnet mask for the guest.
      [string]$SubnetMask  = '255.255.0.0',
      
      #String. The gateway for the guest.
      [string]$Gateway     = '10.205.1.1',
      
      #String. The DNS for the guest. This can be a real internal DNS server, or 8.8.8.8 (google dns) if your lab is on a home network. Later we will change this with DSC.
      [string[]]$DnsAddress  = '8.8.8.8',
      
      #String. The DNS Suffix for the guest.
      [string]$DnsSuffix   = 'lab.local',
      
      #String. The name of the vSphere blue folder.
      [string]$Folder      = 'DSC LABS',
      
      #String. The name of the virtual portgroup. The default is "VM Network"
      [string]$PortGroup     = 'VM Network',
      
      #String. The name of the datastore to deploy the virtual machine onto. If not specified, we use the datastore with the most free space.
      [string]$Datastore,
      
      #String. Optionally, enter a command to run on Windows guest at first boot following deployment.
      [string]$RunOnce,
      
      #Switch. Optionally, activate this switch to use PSCredential for guest login always, instead of the default which uses the getnetworkcredential method. 
      [switch]$Strict,
      
      #Switch. Optionally, open a virtual machine console for newly deployed machines.
      [switch]$Console
    
    )
  
    Process {

      If(-not($Server)){
        $Server = $Global:DefaultVIServer | Select-Object -ExpandProperty Name
      }

      ## Handle guest credential (initial login to template). We only use the password portion of this object, unless in Strict mode in which case we use the entire psobject.
      If(-Not($GuestCredential)){
        If($Strict){
          $GuestCredential = Get-Credential -Message 'Enter template user and password'
        }
        Else{
          $GuestCredential = Get-Credential -UserName '(Password Only)' -Message 'Enter template password'
        }
      }

      ## Extract guest password, if needed
      If($Strict){
        ## uses entire PSCredential
        $guestPassword = $GuestCredential
      }
      Else{
        ## Just the password
        $guestPassword = $GuestCredential.GetNetworkCredential().Password
      }
    
      ## Handle runonce defaults
      If(-not $RunOnce -or $null -eq $RunOnce -or $RunOnce -eq ''){
        $RunOnce = 'powershell.exe Update-Help -ea Ignore; Start-Sleep -Seconds 10; Restart-Computer -Force'
      }

      $exists = Get-VM -Name $Name -ea Ignore
      If($null -eq $exists){
        
          If($VMHost){
            try{
              $VMHostImpl = Get-VMHost -Name $VMHost -ErrorAction Stop
            }
            catch{
              throw $_
            }
          }
          Else{
            try{
              $VMHostImpl = Get-VMHost | Where-Object {$_.ConnectionState -eq 'Connected'} | Select-Object -First 1
            }
            catch{
              throw $_
            }
          }
          
          If($null -eq $VMHostImpl){
            throw 'Problem getting ESXi host object!'
          }
          
          ## Handle datastore
          If($Datastore){
            try{
              ## Use Datastore parameter 
              $ds = Get-Datastore -Name $Datastore -ErrorAction Stop
            }
            catch{
              throw $_
            }
          }
          Else{
            try{
              ## Use largest datastore
              $ds = Get-Datastore | Sort-Object FreeSpaceGB -Descending | Select-Object -First 1
            }
            catch{
              throw $_
            }
          }
          
          ## Create Folder, if needed
          $existsFolder = Get-Folder $Folder -ErrorAction Ignore
          If(-Not($existsFolder)){
            
              try{
                  $null = New-Folder -Name $Folder -Location "vm" -ErrorAction Stop
                  Write-Verbose -Message ('Created folder {0}' -f $Folder)
              }
              catch{
                  Write-Error -Message $Error[0].exception.Message
                  throw ('Problem creating folder {0}' -f $Folder)
              }
          }
        
          ## Remove existing customization spec, if needed
          $strScriptSpec = ('ScriptSpec-{0}' -f $Name)
          $specExists = Get-OSCustomizationSpec -Name $strScriptSpec -ErrorAction Ignore
          If($specExists){
              $null = Get-OSCustomizationSpec -Name $strScriptSpec | Remove-OSCustomizationSpec -Confirm:$false -ErrorAction SilentlyContinue
          }

          ## Create customization spec
          $null = New-OSCustomizationSpec -Server $Server `
          -Name $strScriptSpec `
          -Description "Customization Spec for $($Name)" `
          -FullName $FullName `
          -OrgName $OrgName `
          -AdminPassword $guestPassword `
          -TimeZone $TimeZone `
          -ChangeSid `
          -Workgroup 'Workgroup' `
          -DnsSuffix $DnsSuffix `
          -NamingScheme Fixed `
          -NamingPrefix $Name `
          -AutoLogonCount '1' `
          -GuiRunOnce $RunOnce `
          -Confirm:$false
    
          ## Set the vNIC mapping
          $null = Get-OSCustomizationSpec $strScriptSpec -Server $Server | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping `
          -IpMode UseStaticIP -IpAddress $IPAddress -SubnetMask $SubnetMask -DefaultGateway $Gateway -Dns $DnsAddress
    
          ## Get the final spec object
          $specObj = Get-OSCustomizationSpec $strScriptSpec -Server $Server
   
          ## Deploy Virtual Machine
          $dt = (Get-Date -Format o)
          
          If($null -ne $Description){
            $strNotes = ('{0} for {1} deployed using {2} at {3}' -f $Description, $site, $Template, $dt)
          }
          Else{
            $strNotes = ('Deployed using {0} at {1}' -f $Template, $dt)
          }
          
          try{
            $null = New-VM -Name $Name `
            -Template (Get-Template -Name $Template) `
            -VMHost $VMHostImpl `
            -Location (Get-Folder -Name $Folder) `
            -OSCustomizationSpec $specObj `
            -Datastore $ds `
            -DiskStorageFormat 'Thin' `
            -Notes $strNotes `
            -ErrorAction Stop
          }
          catch{
            Write-Warning -Message ('Problem deploying {0}!' -f $Name)
            throw $_
          }
          
          # Confirm the new VM has been created and has a network adapter
          $startTimerVM = Get-Date
          do {if ((new-timespan $startTimerVM).TotalSeconds -le 300) {$timedout = Get-VM -Name $Name | Get-NetworkAdapter; Start-Sleep -Seconds 10} else {$timedout = 'timed out'}} while ($Null -eq $timedout)
          if ($timedout -eq 'timed out') {Write-Warning -Message "Confirmation of VM Network Adapter $($timedout)"}
      
          ## Set the network
          $null = Get-VM -Name $Name | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $PortGroup -Confirm:$false
          
          ## Add CPU and Memory
          $null =  Get-VM -Name $Name | Set-VM -MemoryGB $MemoryGB -NumCPU $NumCPU -Confirm:$false
   
          ## Remove customization spec
          $null =  Remove-OSCustomizationSpec $specObj -Confirm:$false -ErrorAction SilentlyContinue
   
          ## Power on VM
          $null =  Start-VM -VM $Name -Confirm:$false       
          
          ## Handle console launch, if needed
          If($Console){
            Open-VMConsoleWindow -VM (Get-VM $Name)
          }
      }
      Else{
        Write-Host ('Virtual machine {0} exists (skipping!)' -f $Name) -ForegroundColor Yellow -BackgroundColor DarkYellow
      }
    }
}