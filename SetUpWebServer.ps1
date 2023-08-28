
##### IIS Installation #####
### to get the IIS machine key(DecryptionKey & ValidationKey), we need to complete IIS installation first
Add-WindowsFeature Web-Server,Web-Request-Monitor,Web-Http-Tracing,Web-Windows-Auth,Web-App-Dev,Web-ASP,Web-Asp-Net,Web-Asp-Net45,Web-CGI,Web-AppInit,Web-Includes,Web-Mgmt-Tools,Web-Scripting-Tools,Web-Mgmt-Service,Web-Http-Redirect,Web-Dyn-Compression

##########################################################################################################################################################################
### to set up the new server, you need to complete the line 8 for IIS installation to get the machine key to copy to the follow section.
##########################################################################################################################################################################

##### Variables Definition #####

$hostName = [System.Net.Dns]::gethostentry('localhost').HostName
$WebSiteName = "WebSiteName"
$ServiceAccount = "Account To run your apps"
$ShareFolder = "Location of your apps"
$ShareConfigurationFolder = "Location of the shared configuration files"

$ShareConfigurationAccount = 'Account to access shared configuration'
$ShareConfigurationPWD = "Password for shared configuration account"
$ShareConfigurationKey = "Shared configuration key"
$ServiceAccountPWD = "Password for service account"
$ShareConfigEnabled = $false


##### Import Module #####
Import-Module WebAdministration


##### Stop Services #####
Stop-Service -Name 'WMSVC' -Force
Stop-Service -Name 'WAS' -Force


##### ------------------------------------------------------------------------------------------------------------------------------------------------------------------ #####
##### Fully Qualified URL (FQURL) #####
### Install Web Platform Installer
Start-Process -FilePath "$PSScriptRoot\WebPlatformInstaller_amd64_en-US.msi" '/qn' -wait
### Install URL Rewrite Module
Start-Process -FilePath "$PSScriptRoot\rewrite_amd64_en-US.msi" '/q' -wait
#Start-Process -FilePath 'C:\Program Files\Microsoft\Web Platform Installer\WebpiCmd.exe' -ArgumentList '/Install /Products:UrlRewrite2 /AcceptEULA' -Verb Runas -Wait
### Create basic FQURL rule
if ([System.Net.Dns]::gethostentry('localhost').HostName.Split('.').Count -eq 3){
    $Pattern = '.domain.com'
    $URL = 'http://{HTTP_HOST}.domain.com/{R:0}'
}else{
    $Pattern = [System.Net.Dns]::gethostentry('localhost').HostName.Split('.')[1] + '.domain.com'
    $URL = 'http://{HTTP_HOST}.' + [System.Net.Dns]::gethostentry('localhost').HostName.Split('.')[1] + '.domain.com/{R:0}'
}
Add-WebConfigurationProperty -Filter 'system.webServer/rewrite/globalRules' -Name '.' -Value @{name='FQURL';stopProcessing='true'}
Set-WebconfigurationProperty -Filter 'system.webServer/rewrite/globalRules/rule[@name="FQURL"]/match' -Name 'url' -Value '.*'
Add-WebConfiguration -Filter 'system.webServer/rewrite/globalRules/rule[@name="FQURL"]/conditions' -Value @{input='{HTTP_HOST}';pattern=$Pattern;negate='true'}
Set-WebconfigurationProperty -Filter 'system.webServer/rewrite/globalRules/rule[@name="FQURL"]/action' -Name 'type' -Value 'Redirect'
Set-WebconfigurationProperty -Filter 'system.webServer/rewrite/globalRules/rule[@name="FQURL"]/action' -Name 'url' -Value $URL

Start-Process -FilePath "$PSScriptRoot\IISCORS_amd64.msi" '/q' -wait

##### Install Dotnet Core #####
Start-Process -FilePath "$PSScriptRoot\dotnet-hosting-2.2.7-win.exe" '/q' -wait
Start-Process -FilePath "$PSScriptRoot\dotnet-hosting-3.1.2-win.exe" '/q' -wait


##### Rename Default Web Site #####
if ((Get-Website).name.Contains('Default Web Site')) { Set-WebConfiguration -Filter 'system.applicationHost/sites/site[@name="Default Web Site"]' -Value @{name=$WebSiteName} }

##### Define App Pools #####
Set-WebconfigurationProperty -Filter 'system.applicationHost/applicationPools/applicationPoolDefaults' -Name 'enable32BitAppOnWin64' -Value 'true'
Set-WebconfigurationProperty -Filter 'system.applicationHost/applicationPools/applicationPoolDefaults/processModel' -Name 'identityType' -Value 'SpecificUser'
Set-WebconfigurationProperty -Filter 'system.applicationHost/applicationPools/applicationPoolDefaults/processModel' -Name 'userName' -Value $ServiceAccount
Set-WebconfigurationProperty -Filter 'system.applicationHost/applicationPools/applicationPoolDefaults/processModel' -Name 'password' -Value $ServiceAccountPWD
Set-WebconfigurationProperty -Filter 'system.applicationHost/applicationPools/applicationPoolDefaults/recycling' -Name 'logEventOnRecycle' -Value 'Time,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory'
Add-WebConfiguration -Filter 'system.applicationHost/applicationPools' -Value @{name='PERL'}
Add-WebConfiguration -Filter 'system.applicationHost/applicationPools' -Value @{name='ASP'}
Add-WebConfiguration -Filter 'system.applicationHost/applicationPools' -Value @{name='ASPNET64';enable32BitAppOnWin64='true'}


##### Windows Authentication #####
Set-WebconfigurationProperty -Filter 'system.webServer/security/authentication/windowsAuthentication' -Name 'enabled' -Value 'true'
Set-WebconfigurationProperty -Filter 'system.webServer/security/authentication/windowsAuthentication' -Name 'useAppPoolCredentials' -Value 'true'
Set-WebconfigurationProperty -Filter 'system.webServer/security/authentication/anonymousAuthentication' -Name 'enabled' -Value 'false'


##### Create Custom Local Directories #####
New-Item -ItemType 'directory' -Path 'C:\inetpub\wwwroot\webtemp'
New-Item -ItemType 'directory' -Path 'C:\Program Files (x86)\netegrity\webagent\Log'
New-Item -ItemType 'directory' -Path 'C:\Program Files\netegrity\webagent\Log'


##### Localhost Group Membership #####
Add-LocalGroupMember -Group 'IIS_IUSRS' -Member $ServiceAccount
Add-LocalGroupMember -Group 'Administrators' -Member "YourAdminUser"

##### Localhost NTFS File Permissions #####
SetFolderPermission 'C:\inetpub\wwwroot\webtemp'
SetFolderPermission 'C:\windows\temp'
SetFolderPermission 'C:\Program Files (x86)\netegrity\webagent\Log'
SetFolderPermission 'C:\Program Files\netegrity\webagent\Log'


##### Virtual Web Site Home Directory #####
Set-WebconfigurationProperty -Filter "system.applicationHost/sites/site[@name='$WebSiteName']/application[@path='/']/virtualDirectory[@path='/']" -Name 'physicalPath' -Value $ShareFolder
Set-WebConfigurationProperty -Filter "system.applicationHost/sites/site[@name='$WebSiteName']/application[@path='/']/virtualDirectory[@path='/']" -Name 'userName' -Value $ServiceAccount
Set-WebConfigurationProperty -Filter "system.applicationHost/sites/site[@name='$WebSiteName']/application[@path='/']/virtualDirectory[@path='/']" -Name 'password' -Value $ServiceAccountPWD
Set-WebconfigurationProperty -Filter 'system.applicationHost/sites/virtualDirectoryDefaults' -Name 'userName' -Value $ServiceAccount
Set-WebconfigurationProperty -Filter 'system.applicationHost/sites/virtualDirectoryDefaults' -Name 'password' -Value $ServiceAccountPWD

$Path = $ShareFolder + '\web.config'
$XML = [Xml](Get-Content $Path)
$result = $XML.configuration.'system.web'.compilation.buildProviders
if ($result -eq $null) {
    $customErrors = $XML.CreateElement('customErrors')
    $customErrors.SetAttribute('mode','Off')
    $compilation = $XML.CreateElement('compilation')
    $compilation.SetAttribute('debug','true')
    $assemblies = $XML.CreateElement('assemblies')
    $assembliesadd = $XML.CreateElement('add')
    $assembliesadd.SetAttribute('assembly','YourAssemblyInfo')
    $buildProviders = $XML.CreateElement('buildProviders')
    $buildProvidersadd = $XML.CreateElement('add')
    $buildProvidersadd.SetAttribute('extension','.ekg')
    $buildProvidersadd.SetAttribute('type','System.Web.Compilation.PageBuildProvider')

    $XML.configuration.'system.web'.AppendChild($customErrors)
    $XML.configuration.'system.web'.AppendChild($compilation)
    $XML.configuration.'system.web'.compilation.AppendChild($assemblies).AppendChild($assembliesadd)
    $XML.configuration.'system.web'.compilation.AppendChild($buildProviders).AppendChild($buildProvidersadd)
    $XML.Save($Path)
}
### Install web common library
if (!(Test-Path -Path ($ShareFolder + '\bin'))) {
    New-Item -ItemType 'directory' -Path ($ShareFolder + '\bin')
}
### Create the settings in applicationHost.config to disable the Windows Authentication for health.ekg
#if ($ISProd) { $Path = $ShareConfigurationFolder + '\applicationHost.config' }else{ $Path = 'C:\Windows\System32\inetsrv\config\applicationHost.config' }
$XML = [Xml](Get-Content $Path)
$result = $XML.configuration.location.'system.webServer'.security.authentication
if ($result -eq $null) {
    $location = $XML.CreateElement('location')
    $location.SetAttribute('path',$WebSiteName + '/health.ekg')
    $system_webServer = $XML.CreateElement('system.webServer')
    $security = $XML.CreateElement('security')
    $authentication = $XML.CreateElement('authentication')
    $windowsAuthentication = $XML.CreateElement('windowsAuthentication')
    $windowsAuthentication.SetAttribute('enabled','false')
    $anonymousAuthentication = $XML.CreateElement('anonymousAuthentication')
    $anonymousAuthentication.SetAttribute('enabled','true')

    $XML.configuration.AppendChild($location).AppendChild($system_webServer).AppendChild($security).AppendChild($authentication).AppendChild($windowsAuthentication)
    $XML.configuration.location.'system.webServer'.security.authentication.AppendChild($anonymousAuthentication)
    $XML.Save($Path)
}


##### Environment Settings #####
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + ';%systemroot%\system32\inetsrv', [EnvironmentVariableTarget]::Machine)

##### Remote Management #####
Set-Service -Name 'WMSVC' -StartupType 'Automatic'
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WebManagement\Server' -Name 'EnableRemoteManagement' -Value '1'

##### .NET Configuration #####
### .NET Session State
Start-Service -Name 'aspnet_state'
Set-Service -Name 'aspnet_state' -StartupType 'Automatic'
### .NET Cluster Validation and Decryption key
SetMachineKey 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\CONFIG\web.config'
SetMachineKey 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\CONFIG\web.config'

##### Database Drivers #####
##### Please note that the one who wants to install softwares from software center should be the one with smallest user ID on Task Manager(The first one to login the server) #####
$Target_item = Get-WmiObject -Class CCM_Program -Namespace "root\ccm\clientsdk" | Where-Object { $_.PackageName -like "*oracle client 11G*" -and $_.Name -eq "Install" }
Invoke-WmiMethod -class CCM_ProgramsManager -Namespace "root\ccm\clientsdk" -Name ExecutePrograms  -argumentlist $Target_item
$Target_item = Get-WmiObject -Class CCM_Program -Namespace "root\ccm\clientsdk" | Where-Object { $_.PackageName -like "*Teradata*" -and $_.Name -eq "Install" }
Invoke-WmiMethod -class CCM_ProgramsManager -Namespace "root\ccm\clientsdk" -Name ExecutePrograms  -argumentlist $Target_item
$Target_item = Get-WmiObject -Class CCM_Program -Namespace "root\ccm\clientsdk" | Where-Object { $_.PackageName -like "*Microsoft ODBC Driver 11 for SQL Server*" -and $_.Name -eq "Install" }
Invoke-WmiMethod -class CCM_ProgramsManager -Namespace "root\ccm\clientsdk" -Name ExecutePrograms  -argumentlist $Target_item
$Target_item = Get-WmiObject -Class CCM_Program -Namespace "root\ccm\clientsdk" | Where-Object { $_.PackageName -like "*Microsoft Access Database Engine 2010*" -and $_.Name -eq "Install" }
Invoke-WmiMethod -class CCM_ProgramsManager -Namespace "root\ccm\clientsdk" -Name ExecutePrograms  -argumentlist $Target_item

##### Miscellaneous Configurations #####
Set-WebConfigurationProperty -Filter 'system.webServer/asp' -Name enableParentPaths -Value $true
Set-WebConfigurationProperty -Filter 'system.applicationHost/sites/siteDefaults/logFile' -Name localTimeRollover -Value $true
Set-WebConfigurationProperty -Filter 'system.applicationHost/sites/siteDefaults/logFile' -Name LogExtFileFlags -Value 'Date,Time,ClientIP,UserName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,TimeTaken,UserAgent,Referer,ProtocolVersion,HttpSubStatus'


$comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
$applications = $comAdmin.GetCollection("Applications")
$applications.Populate()
$targetApp = 'DATCom'
$application = $applications | Where-Object {$_.Name -eq $targetApp}
$comAdmin.ShutdownApplication($targetApp)

$application.Value('Identity') = 'NT AUTHORITY\NetworkService'
$applications.SaveChanges()
$comAdmin.StartApplication($targetApp)

Set-Itemproperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters' -Name 'LogLevel' -value 0
