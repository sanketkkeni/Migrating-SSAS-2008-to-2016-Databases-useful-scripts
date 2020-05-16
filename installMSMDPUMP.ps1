# Name: Configure HTTP Access to Analysis Services on IIS 
# Created by: Sanket Keni
# Date created: 09/09/2019
# Scope: ******
# Description: This PS Script is used to Configure HTTP Access to Analysis Services on IIS. It is part of setup process when installing an SSAS Instance on a server. This is because SAP Users use HTTP to access SSAS Databases.
# Notes: This script assumes only 1 SSAS instance per server.

###################################################################
###### Running the Script in Powershell from local machine#########
#Enable-PSRemoting -Force (Required only once per local machine)
#Test-WsMan ServerName
#Reboot all the remote machines to get through with pending reboots before proceeding with installing IIS::
#Restart-Computer -ComputerName Server1,Server2,Server_N -Wait -For PowerShell -Timeout 300 -Delay 10 -Force
#Invoke-Command -FilePath "C:\_src\SE.Install.SSAS.2016\installMSMDPUMP.ps1" -ComputerName Server1,Server2,Server_N
####################################################################


# Re-Check if a reboot is pending on the server 
function Test-PendingReboot
{
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
 if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($status -ne $null) -and $status.RebootPending){
     return $true
   }
 }catch{}
 
 return $false
}

if (Test-PendingReboot == true) {
    Write-Host "A reboot is still pending on the server:" $env:COMPUTERNAME " Please use the installMSMDPUMP_RUN-FILE-LOCALLY.ps1 script"
    RETURN
}

# Check if IIS is installed
if ((Get-WindowsFeature Web-Server).InstallState -eq "Installed") {
    Write-Host "IIS is installed on" $env:COMPUTERNAME
    RETURN
}

#Installing IIS
Install-WindowsFeature -Name web-Server -IncludeManagementTools
Write-Host "IIS is already Installed"

#Enabling the required features of IIS
Write-Host "Enabling the required features of IIS:"
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CGI
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
#Enable-WindowsOptionalFeature -Online -FeatureName IIS-BasicAuthentication #Not Required
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication

# Get the SSAS Instance name
Write-Host "Getting the SSAS Instance name"
$ssas_instance = Get-WmiObject win32_Service | where {$_.DisplayName -match "SQL Server Analysis Services"} | select DisplayName
$string = $ssas_instance[0].DisplayName
$regex = [regex] "\(([^\(]*)\)"
$instance_name = $regex.match($string).Value
$instance_name = $instance_name.Substring(1,$instance_name.Length-2)
$Server_name_value = $env:COMPUTERNAME + '\' + $instance_name

Write-Host "Instance Name is:" $instance_name

#Copy the MSMDPUMP files
Write-Host "Copying the MSMDPUMP files"
[string]$sourceDirectory  = "E:\Program Files\Microsoft SQL Server\MSAS13." + $instance_name + "\OLAP\bin\isapi\*"
[string]$destinationDirectory = "C:\inetpub\wwwroot\OLAP\"
New-Item -ItemType Directory -Force -Path $destinationDirectory
Copy-item -Force -Recurse -Verbose $sourceDirectory -Destination $destinationDirectory


#Creating Application Pool
Write-Host "Creating Application Pool: OLAP"
Import-Module WebAdministration
New-WebAppPool OLAP
Set-ItemProperty IIS:\AppPools\OLAP managedPipelineMode Classic

#Convert Virtual Directory to Application
Write-Host "Converting Virtual Directory to Application"
ConvertTo-WebApplication "IIS:\Sites\Default Web Site\OLAP" -ApplicationPool OLAP

#Disable Anon Authentication
Write-Host "Disabling Anonymous Authentication"
Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/AnonymousAuthentication -name enabled -value false -location C:\inetpub\wwwroot\OLAP


#Enable Basic and Windows Authentication
Write-Host "Enabling Basic and Windows Authentication"
Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/BasicAuthentication -name enabled -value true -location C:\inetpub\wwwroot\OLAP
Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/WindowsAuthentication -name enabled -value true -location C:\inetpub\wwwroot\OLAP


#Add Script map
Write-Host "Adding Script map"
Set-WebConfiguration //System.webServer/handlers -metadata overrideMode -value Allow -PSPath IIS:/ -verbose

New-WebHandler -Name "OLAP" -Path "*.dll" -Verb "*" -ResourceType "File" -Modules "IsapiModule" -PSPath "IIS:\sites\Default Web Site\OLAP" -ScriptProcessor "C:\inetpub\wwwroot\OLAP\msmdpump.dll"


# Edit the msmdpump.ini file with SSAS Instance
Write-Host "Editing the msmdpump.ini file with SSAS Instance:" $Server_name_value
$configFilePath = 'C:\inetpub\wwwroot\OLAP\msmdpump.ini'
[xml] $xml = Get-Content $configFilePath
$xml.ConfigurationSettings.ServerName = $Server_name_value
$xml.Save($configFilePath)

# Enabling ISAPI and CGI Restrictions
Write-Host "Enabling ISAPI and CGI Restrictions"
C:\Windows\System32\inetsrv\appcmd.exe set config -section:system.webServer/security/isapiCgiRestriction /+"[path='c:\inetpub\wwwroot\OLAP\msmdpump.dll',allowed='True',groupId='OLAP',description='OLAP']" /commit:apphost 

# URL to use from SSMS
$url = "http://" + $env:COMPUTERNAME + "/olap/msmdpump.dll"
# DONE!!!
Write-Host "IIS is now configured for HTTP access"
Write-Host "Use the following while logging into Analysis Server from SSMS:" $url









