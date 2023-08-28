$server = ""
$webApps = invoke-command -ComputerName $server -ScriptBlock {
    Import-Module WebAdministration
    $webAppsInfo = Get-WebApplication
    $webAppsInfo = $webAppsInfo | Sort-Object -Property path

    $row = [Ordered]@{}
    foreach ($webAppInfo in $webAppsInfo)
    {
        $applicationName = $webAppInfo.path.Substring(1)
        $applicationPoolName = $webAppInfo.applicationPool
        $physicalPath = $webAppInfo.PhysicalPath
        $credential = ($webAppInfo.collection | Select-Object username).username
        $applicationPool = GEt-Item IIS:\AppPools\$applicationPoolName
        $managedPipelineMode = $applicationPool.managedPipelineMode
        $managedRuntimeVersion = $applicationPool.managedRuntimeVersion
        $row[$applicationName] = @{'applicationPoolName' = $applicationPoolName; 'physicalPath' = $physicalPath; 'credential' = $credential; 'managedPipelineMode' = $managedPipelineMode; 'managedRuntimeVersion' = $managedRuntimeVersion}
    }
    $row
}
$webApps
