
$computers = 'servername'
$outputs = Invoke-Command -ComputerName $computers -ScriptBlock{
    # the time should use the timezone on that server.
    $Begin = Get-Date -Date ('12/14/2022 00:00:00')
    $End = Get-Date -Date ('12/15/2022 09:00:00')
    $applicationName = 'Application Pool Name'
    $applicationLogs = Get-EventLog -LogName Application -source "*ASP.NET*" -Message "*$applicationName*" -After $Begin -Before $End | select EntryType, MachinName, Site, Source, TimeGenerated, UserName, Message
    $systemLogs = Get-EventLog -LogName System -source WAS -Message "*$applicationName*" -After $Begin -Before $End | select EntryType, MachinName, Site, Source, TimeGenerated, UserName, Message
    
    $output = @{}
    $output['applicationLogs'] = $applicationLogs
    $output['systemLogs'] = $systemLogs
    $output['applicationName'] = $applicationName
    $output['serverName'] = $env:computername
    $output

}

$applicationName = $outputs[0]['applicationName']
$timeNow = Get-Date -Format "MMddHHmm"
$fileName = $applicationName + $timeNow

$objExcel = New-Object -ComObject Excel.Application
$FilePath = "C:\TEMP\eventlog\$fileName.xlsx"
$WorkBook = $objExcel.Workbooks.Add()
$WorkSheet = $WorkBook.sheets.item( "Sheet1" )

$WorkSheet.Range("A1").Value = 'EntryType'
$WorkSheet.Range("B1").Value = 'ServerName'
$WorkSheet.Range("C1").Value = 'Site'
$WorkSheet.Range("D1").Value = 'Source'
$WorkSheet.Range("E1").Value = 'TimeGenerated'
$WorkSheet.Range("F1").Value = 'UserName'
$WorkSheet.Range("G1").Value = 'Message'
$index = 2

foreach ($output in $outputs)
{
    $applicationLogs = $output['applicationLogs']
    $systemLogs = $output['systemLogs']
    $serverName = $output['serverName']
    
    foreach ($applicationLog in $applicationLogs)
    {
        $EntryType = $applicationLog.EntryType
        $MachinName = $applicationLog.MachinName
        $Site = $applicationLog.Site
        $Source = $applicationLog.Source
        $TimeGenerated = $applicationLog.TimeGenerated
        $UserName = $applicationLog.UserName
        $Message = $applicationLog.Message
        $WorkSheet.Range("A$index").Value = [string]$EntryType
        $WorkSheet.Range("B$index").Value = [string]$serverName
        $WorkSheet.Range("C$index").Value = [string]$Site
        $WorkSheet.Range("D$index").Value = [string]$Source
        $WorkSheet.Range("E$index").Value = [string]$TimeGenerated
        $WorkSheet.Range("F$index").Value = [string]$UserName
        $WorkSheet.Range("G$index").Value = [string]$Message
        ++$index
    }
    foreach ($systemLog in $systemLogs)
    {
        $EntryType = $systemLog.EntryType
        $MachinName = $systemLog.MachinName
        $Site = $systemLog.Site
        $Source = $systemLog.Source
        $TimeGenerated = $systemLog.TimeGenerated
        $UserName = $systemLog.UserName
        $Message = $systemLog.Message
        $WorkSheet.Range("A$index").Value = [string]$EntryType
        $WorkSheet.Range("B$index").Value = [string]$serverName
        $WorkSheet.Range("C$index").Value = [string]$Site
        $WorkSheet.Range("D$index").Value = [string]$Source
        $WorkSheet.Range("E$index").Value = [string]$TimeGenerated
        $WorkSheet.Range("F$index").Value = [string]$UserName
        $WorkSheet.Range("G$index").Value = [string]$Message
        ++$index
    }
}




$WorkBook.SaveAs($FilePath)
$objExcel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WorkSheet)
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WorkBook)
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($objExcel)
Remove-Variable objExcel
