$computerName = $env:computername
$packageName = "VMware Tools"
$packageVersion = "12.1.5.20735119"
$backupLogPath = "C:\logs\VMWareTools_InstallHistory"

$InstallFlag = $true
$script:returnMessage = ""
$Script:returnMessage += "ComputerName is $computerName`n"

Try {
    $ItemInfo = $null
    $ItemInfo = Get-ChildItem "C:\logs\VMWare_Inc_VMware_Tools*$packageVersion*_INSTALL*"
    if ($ItemInfo -and $InstallFlag) {
        #move Exist Log to History
        New-Item -ItemType Directory -Force -Path $backupLogPath
        Move-Item -Path $ItemInfo.FullName -Destination "$($backupLogPath)\$($ItemInfo.Name)_$((Get-Date).ToString("yyyyMMddHHmmss"))"
    }
    $vendor = (Get-CIMInstance -ComputerName $computerName  Win32_ComputerSystemProduct).Vendor
    if($vendor.Contains("VMware")) {
        $script:returnMessage += "$computerName is a VM!`n"
        [String]$version = Get-CIMInstance Win32_Product -ComputerName $computerName | where Name -eq $packageName | select Version
        $script:returnMessage += "$computerName VMTools: $version`n"
        if($version.Contains($packageVersion))
        {
            $script:returnMessage += "$computerName contains latest version! Ignoring VMTools Upgrade Action!`n"
        }
        else
        {
            $script:returnMessage += "Proceed to upgrade VMware Tools on $computerName`n"
            $installable = Get-WmiObject  -Namespace "root\CCM\Policy\Machine\ActualConfig" -Class "CCM_SoftwareDistribution" -Filter "PKG_Name = '$packageName' AND PKG_version = '$packageVersion' AND PRG_PRF_Disabled = FALSE" | Select-Object PKG_PackageID, ADV_AdvertisementID, PRG_ProgramName -ExcludeProperty TS_Sequence | Where-Object { $_.PRG_ProgramName -eq 'Install' }
            if (-not  $installable -and $installable.count -ne 1) {
                throw "There is no VMWare package on $computerName"
            }
            else {
                $Script:returnMessage += "There has $packageName package`n"
                $scriptStartDate = Get-Date
                $installionTimeFrameMins = 10

                $Script:returnMessage += "ADV_ID found: $($installable.ADV_AdvertisementID)`n"
                $Script:returnMessage += "PRG_ProgramName found: $($installable.PRG_ProgramName)`n"

                $a = ([wmi]"ROOT\ccm\policy\machine\actualconfig:CCM_SoftwareDistribution.ADV_AdvertisementID='$($installable.ADV_AdvertisementID)',PKG_PackageID='$($installable.PKG_PackageID)',PRG_ProgramID='$($installable.PRG_ProgramName)'")
                $a.ADV_MandatoryAssignments = $true
                $a.Put()
                $xml = New-Object XML
                $xml.Loadxml($a.PRG_Requirements)
                $ScheduleID = $xml.SWDReserved.ScheduledMessageID
                $Script:returnMessage += "ScheduleID is $ScheduleID`n"
                ([wmiclass]"ROOT\ccm:SMS_Client").TriggerSchedule($ScheduleID)
            }

            $fgVersionFound = $false
            $fgInstallResult = $false
            $logfile = $null
            do {
                Start-Sleep -Seconds 30
                $content = Get-Content -Path "C:\logs\VMWare_Inc_VMware_Tools*$packageVersion*_INSTALL*" -ErrorAction Ignore
                
                $fgVersionFound = $false
                $fgInstallResult = $false
                if ($content) {
                    foreach ($currentRow in $content) {
                        if ($logfile) {
                            if ($currentRow -like "*INSTALL.BAT*Started*") {
                                $logfile = $null
                                $fgVersionFound = $false
                                $fgInstallResult = $false
                            }
                        }
                        if ($fgVersionFound) {
                            if ($currentRow -like "*ReturnCode: Error*") {
                                $script:returnMessage += "Found INSTALL.BAT - Unfinished:$currentRow"
                                $fgInstallResult = $false
                                $logfile = $true
                            }
                            if (($currentRow -like "*ReturnCode: 0*") -or ($currentRow -like "*ReturnCode: 3010*")) {
                                $script:returnMessage += "Found INSTALL.BAT - Finished"
                                $fgInstallResult = $true
                                $logfile = $true
                            }
                        }
                        else {
                            if ($currentRow -like "*Installing*VMWare*Inc*VMware*Tools*$packageVersion*") {
                                $fgVersionFound = $true
                            }
                        }
                    }
                }
            } while ( -not $logfile -and (Get-Date).Subtract($scriptStartDate).Minutes -le $installionTimeFrameMins )

            if (-not $fgInstallResult) {
                $returnStatus = "Fail"
                throw "Failed to install $packageName on $computerName and Return Message is $Script:returnMessage"
            }
            $script:returnMessage += "The $packageName installed complete."
        }
        
    }
    else {
        $script:returnMessage = "$computerName is $vendor! Ignoring VMTools Upgrade Action!`n"
    }
}
Catch {
    $script:returnMessage = $_.Exception.Message
}
Finally {
}
