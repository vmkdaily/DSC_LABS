## Optional - How to configure remote node proxy server for PSGallery (optional)

##Intro
## This configures the Internet Explorer proxy on a remote node.
## You may not need a proxy server. Adjust as needed to reflect
## your desired proxy, if any.

$ComputerName = 's1'
$Credential = Get-Credential
$session = New-PSSession -ComputerName $ComputerName -Credential $Credential

Invoke-Command -Session $session -ScriptBlock {
  
  #your proxy info
  $proxyURI = '10.1.2.3:8080' #your upstream proxy address here
  $bypassList = "lab.local"
  
  ## code snippet from user `Timje` at:
  ## https://stackoverflow.com/questions/48166882/using-powershell-to-programmatically-configure-internet-explorer-proxy-settings
  function Set-Proxy($Proxy, $BypassUrls){
    $proxyBytes = [system.Text.Encoding]::ASCII.GetBytes($proxy)
    $bypassBytes = [system.Text.Encoding]::ASCII.GetBytes($bypassUrls)
    $defaultConnectionSettings = [byte[]]@(@(70,0,0,0,0,0,0,0,11,0,0,0,$proxyBytes.Length,0,0,0)+$proxyBytes+@($bypassBytes.Length,0,0,0)+$bypassBytes+ @(1..36 | % {0}))
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $registryPath -Name ProxyServer -Value $proxy
    Set-ItemProperty -Path $registryPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path "$registryPath\Connections" -Name DefaultConnectionSettings -Value $defaultConnectionSettings
    netsh winhttp set proxy $proxy bypass-list=$bypassUrls
  }
  Set-Proxy -Proxy $proxyURI -BypassUrls $bypassList
  
}