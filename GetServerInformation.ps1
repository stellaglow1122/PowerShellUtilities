#*******************************************************************************************************
# Author: stellaglow1122
# Date:   2020/04/27
# Memo:   1. Check all web servers
#         2. Get information about the servers
#         3. Output to an html file
#*******************************************************************************************************
$content = @()
$list = ""
$head = ""
#total agent number
$totalCount = 0
$StartDate = GET-DATE -Format "yyyy-MM-dd"

$head += "<head><Title>Web Servers List</Title>
           <link rel='stylesheet' href='https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css' integrity='sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh' crossorigin='anonymous'>
           <style>             
                th {background-color: #1aa3ff; color: #000000; font-family: Calibri; font-size: 18px}
                p {font-family: Calibri; font-size: 12px; color: #808080}
                table {text-align:center;}
                .col-md-12 {margin:20px;}
                #number {color: #333333}
                .subtitle{margin:20px;}
           </style></head><div class='container-fluid'>"

$content+=$head

#scan servers
$applicationServerList = @()
$serverLists = @($applicationServerList)
$i = 0
$site = @{'SiteCode' = 'SiteName'}
foreach($serverList in $serverLists)
{    
    #Create table
    $table = New-Object system.Data.DataTable “table”
    $col0 = New-Object system.Data.DataColumn Site,([string])
    $col1 = New-Object system.Data.DataColumn HostName,([string])
    #$col2 = New-Object system.Data.DataColumn ABATVersion,([string])
    $col2 = New-Object system.Data.DataColumn NumberOfCPU,([string])
    $col3 = New-Object system.Data.DataColumn Memory,([string])
    $col4 = New-Object system.Data.DataColumn OSVersion,([string])
    $col5 = New-Object system.Data.DataColumn LastPatchDate,([string])
    $col6 = New-Object system.Data.DataColumn LastRebootDate,([string])
    #$col8 = New-Object system.Data.DataColumn Owner,([string])
    #Add the Columns
    $table.columns.add($col0)
    $table.columns.add($col1)
    $table.columns.add($col2)
    $table.columns.add($col3)
    $table.columns.add($col4)
    $table.columns.add($col5)
    $table.columns.add($col6)
    #$table.columns.add($col7)
    #$table.columns.add($col8)

    foreach($serverName in $serverList)
    {
        $serverName = $serverName.ToUpper()
        $serverName
        $ping = Test-Connection -ComputerName $serverName -Quiet -Count 1
        if($ping){ #$Agent.State -eq 5 means connected
       
            #Create rows in console
            $row = $table.NewRow()
            
            
            #$AgentName = $AgentCharac.Item("HostName").value

            #Check Windows server last update date and not including Linux
            $lastpatch = Get-WmiObject -ComputerName $serverName Win32_Quickfixengineering -erroraction 'silentlycontinue'| select @{Name="InstalledOn";Expression={$_.InstalledOn -as [datetime]}} | Sort-Object -Property Installedon | select-object -property installedon -last 1
            $lastboot = Get-WmiObject -ComputerName $serverName win32_operatingsystem -erroraction 'silentlycontinue'| select @{Name="LastBootUpTime";Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Select-Object -Property lastbootuptime

            if($lastpatch -and $lastboot -ne $null){
                
                $lastpatchDate = Get-Date $lastpatch.InstalledOn -Format "yyyy-MM-dd"
                $lastbootDate = Get-Date $lastboot.lastbootuptime -Format "yyyy-MM-dd"
                
            }
            else{

                $lastpatchDate = "-"
                $lastbootDate = "-"

            }
            $cs = Get-WmiObject -ComputerName $serverName Win32_ComputerSystem -erroraction 'silentlycontinue'
            $memory = [math]::Ceiling($cs.TotalPhysicalMemory / 1024 / 1024 / 1024)
            $cpu = $cs.NumberOfProcessors

            $os = Get-WmiObject -ComputerName $serverName win32_operatingsystem -erroraction 'silentlycontinue'
            $OSVersion = $os.caption
            #Enter data in the row
            $row.Site = $site[$serverName.Substring(0,2)]
            $row.HostName = $serverName
            $row.NumberOfCPU = $cpu
            $row.Memory = [int]$memory
            $row.OSVersion = $OSVersion
            $row.LastPatchDate = $lastpatchDate
            $row.LastRebootDate = $lastbootDate

            #Add the row to the table
            $table.Rows.Add($row)
        
        }

        #Shows disconnected agents
        else{

            #Create rows in console
            $row = $table.NewRow()
            $row.Site = $site[$serverName.Substring(0,2)]
            $row.HostName = $serverName +" (Disconnected)"
            $row.LastPatchDate = ""
            $table.Rows.Add($row)
        
        }
    }

    #Remove the duplicate column and display the table in console
    $table = $table.DefaultView.ToTable($true) | sort -Property HostName

    $HtmlTable = ""
    #<table class='table' border='1' align='center' cellpadding='7' cellspacing='0' style='color:black;font-family:arial,helvetica,sans-serif;text-align:center;'>
    $HtmlTable += "<table class='table table-striped w-auto' align='center' text-align='center' border='1px solid black'>
                    <thead><tr>
                    <th><b>Site</b></th>
                    <th><b>Host name</b></th>
                    <th><b>Number of CPUs</b></th>
                    <th><b>Memory (GB)</b></th>
                    <th><b>OS version</b></th>
                    <th><b>Last Windows update</b></th>
                    <th><b>Last reboot date</b></th>
               </tr></thead><tbody>"

    

    $count=0

    # Create an HTML version of table
    foreach ($row in $table)
    {
        
        if($row.LastPatchDate -ne "-" -AND $row.LastPatchDate -ne $null -AND $row.LastPatchDate -ne ""){
        
            $lastpatchDate = $row.LastPatchDate
            $days = (NEW-TIMESPAN –Start $StartDate –End $lastpatchDate).Days
            #Write-Host "****************** $row.HostName $row.LastPatchDate"
        
        }

        if($count%2 -eq 0){

            
            if($days -le -90 -AND $row.LastPatchDate -ne "-" -AND $row.LastPatchDate -ne ""){

                $colored = "<td width='220px' bgcolor='yellow'>" + $row.LastPatchDate + "</td>"
        
            }
            else{
            
                $colored = "<td width='220px'>" + $row.LastPatchDate + "</td>"
            
            }

            $HtmlTable += "<tr style='font-size:13px;background-color:#FFFFFF'>
                            <td width='150px'>" + $row.Site + "</td>
                            <td width='150px'>" + $row.HostName + "</td>
                            <td width='150px'>" + $row.NumberOfCPU + "</td>
                            <td width='150px'>" + $row.Memory + "</td>
                            <td width='300px'>" + $row.OSVersion + "</td>
                            $colored
                            <td width='200px'>" + $row.LastRebootDate + "</td>
                            </tr>"  
                             
        }

        else{

            if($days -le -90 -AND $row.LastPatchDate -ne "-" -AND $row.LastPatchDate -ne ""){

                $colored = "<td width='220px' bgcolor='yellow'>" + $row.LastPatchDate + "</td>"
        
            }
            else{
            
                $colored = "<td width='220px' bgcolor='f2f2f2'>" + $row.LastPatchDate + "</td>"
            
            
            }

            $HtmlTable += "<tr style='font-size:13px;background-color:#FFFFFF'>
                            <td width='150px' bgcolor='f2f2f2'>" + $row.Site + "</td>
                            <td width='150px' bgcolor='f2f2f2'>" + $row.HostName + "</td>
                            <td width='150px' bgcolor='f2f2f2'>" + $row.NumberOfCPU + "</td>
                            <td width='150px' bgcolor='f2f2f2'>" + $row.Memory + "</td>
                            <td width='300px' bgcolor='f2f2f2'>" + $row.OSVersion + "</td>
                            $colored
                            <td width='200px' bgcolor='f2f2f2'>" + $row.LastRebootDate + "</td>
                            </tr>"     

        }

        $count++
        $colored = ""

    }
    switch($i)
    {
        0 {$serverType = 'Application Server'}
    }
    ++$i
    $content += "<div class='subtitle'><h5>$serverType</h5>"
    $count = $table.Count
    $content += "<h5>Server numbers: $count</h5>"
    $content += "</div>"
    $content += $HtmlTable
    $content += "</tbody></table>"
    $totalCount += $table.Count
    Write-Host "*************$totalCount**************"
}

foreach($object in $content){

    $list+=$object

}

$list+="<p>This page is updated on $((Get-Date).ToUniversalTime()) (UTC).</br>"`
+"In this page refers to the Last Windows update date</br>"`
+"</p></div>"


$header = "<div class='col-md-12'><h3>Web Server List</h3><h5 id='number'>There are totally $totalCount servers</h5></div>"
$list
ConvertTo-HTML -head $header -PostContent $list |  Out-File "Location To save the file"
