[Datetime]$startDate = "2022-08-15"
[Datetime]$end = "2022-10-17"

$StartTime = (Get-date)
Write-host "[" $StartTime.ToString('yyyy-MM-dd HH:mm:ss') "]...Job start" -ForegroundColor Green


$valueCollection = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()
$errorCollection = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()

# Azure Credential Settings
$User = "username"
$PWord = ConvertTo-SecureString -String "password" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

Connect-AzAccount -Credential $Credential

[array]$SubscriptionList = @("Subscription Name")

foreach($subscription in $SubscriptionList){
    $valueCollection = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()
    $errorCollection = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()
    Set-AzContext -Subscription $subscription
    $start = $startDate
    $RGList_notfilter = Get-AzResourceGroup
    $RGList_notfilter | ForEach -ThrottleLimit 2 -Parallel {
        #Set-AzContext -Subscription $ResourceGroup.Subscription
        foreach($key in $_.tags.keys){
            if(
            ($key.ToLower() -eq "contact" -and $_.tags[$key] -like "*FilterContactName*") -or
            ($key.ToLower() -eq "application" -and $_.tags[$key] -like "*FilterApplicationName*")
            ){
                
                foreach($key in $_.tags.keys){
                    if($key.ToLower() -eq "contact"){
                        $RGcontact = $_.Tags.$key
                    }
                    if($key.ToLower() -eq "costcenter"){
                        $RGcostcenter = $_.Tags.$key
                    }
                }
                $ResourceList = (Get-AzResource -ResourceGroupName $_.ResourceGroupName).ResourceName | Out-String
                $start = $using:start
                $endDate = $using:end
                $localvalueCollection = $using:valueCollection
                $localerrorCollection = $using:errorCollection

                $currentDate = $start.ToString("yyyy-MM-dd")
                $tryCount = 0
                do{
                    $currentCost = Get-AzConsumptionUsageDetail -ResourceGroup $_.ResourceGroupName -StartDate $currentDate -EndDate $currentDate | Measure-Object -Property PretaxCost -Sum
                    if ($currentCost -ne $null)
                    {
                        $localvalueCollection.Add(@{"Subscription"=$subscription; "ResourceGroup"=$_.ResourceGroupName; "Date"=$currentDate; "CostCenter"=$RGcostcenter; "Contact"=$RGcontact; "Cost"=$currentCost.Sum; "Resource"=$ResourceList})
                        break
                    }
                    if ($tryCount -eq 2)
                    {
                        $localvalueCollection.Add(@{"Subscription"=$subscription; "ResourceGroup"=$_.ResourceGroupName; "Date"=$currentDate; "CostCenter"=$RGcostcenter; "Contact"=$RGcontact; "Cost"=0; "Resource"=$ResourceList})
                    }
                    ++$tryCount
                } while ($tryCount -lt 3)
                
                
                $start = $start.AddDays(1)
                if ($currentCost -ne $null)
                {
                    
                    while($start -ne $endDate){
                    
                        $currentDate = $start.ToString("yyyy-MM-dd")
                        $currentCost = Get-AzConsumptionUsageDetail -ResourceGroup $_.ResourceGroupName -StartDate $currentDate -EndDate $currentDate | Measure-Object -Property PretaxCost -Sum
                        if ($currentCost -ne $null)
                        {
                            $localvalueCollection.Add(@{"Subscription"=$subscription; "ResourceGroup"=$_.ResourceGroupName; "Date"=$currentDate; "CostCenter"=$RGcostcenter; "Contact"=$RGcontact; "Cost"=$currentCost.Sum; "Resource"=$ResourceList})
                        }
                        else
                        {
                            $localerrorCollection.Add(@{"Subscription"=$subscription; "ResourceGroup"=$_.ResourceGroupName; "Date"=$currentDate; "CostCenter"=$RGcostcenter; "Contact"=$RGcontact; "Cost"=0; "Resource"=$ResourceList})
                        }
                        #Write-Host "Subscription:" $subscription
                        Write-Host "Resource Group Name:" $_.ResourceGroupName
                        Write-Host "Date:" $currentDate
                        Write-Host "CostCenter:" $RGcostcenter
                        Write-Host "Contact:" $RGcontact
                        Write-Host "Current cost:" $currentCost.Sum 
                        # Write-Host "Resource:" $ResourceList 
                        $start = $start.AddDays(1)
                    }
                }
                else
                {
                    while($start -ne $endDate){
                        $currentDate = $start.ToString("yyyy-MM-dd")

                        #Write-Host "Subscription:" $subscription
                        #Write-Host "Resource Group Name:" $_.ResourceGroupName
                        #Write-Host "Date:" $currentDate
                        #Write-Host "CostCenter:" $RGcostcenter
                        #Write-Host "Contact:" $RGcontact
                        #Write-Host "Current cost:" $currentCost.Sum 
                        #Write-Host "Resource:" $ResourceList 
                        $start = $start.AddDays(1)
                        $localvalueCollection.Add(@{"Subscription"=$subscription; "ResourceGroup"=$_.ResourceGroupName; "Date"=$currentDate; "CostCenter"=$RGcostcenter; "Contact"=$RGcontact; "Cost"=0; "Resource"=$ResourceList})
                    }
                }
                break
            }
       } 
    }

    foreach($errors in $errorCollection)
    {
        #$Subscription = $errors["Subscription"]
        $ResourceGroup = $errors["ResourceGroup"]
        $Date = $errors["Date"]
        $CostCenter = $errors["CostCenter"]
        $Contact = $errors["Contact"]
        $Cost = Get-AzConsumptionUsageDetail -ResourceGroup $ResourceGroup -StartDate $Date -EndDate $Date | Measure-Object -Property PretaxCost -Sum
        $Resource = $errors["Resource"]
        Write-Host "||Error Retry||"
        Write-Host "Resource Group Name:" $ResourceGroup
        Write-Host "Date:" $Date
        Write-Host "CostCenter:" $CostCenter
        Write-Host "Contact:" $Contact
        Write-Host "Current cost:" $Cost.Sum
        $valueCollection.Add(@{"Subscription"=$subscription; "ResourceGroup"=$ResourceGroup; "Date"=$Date; "CostCenter"=$CostCenter; "Contact"=$Contact; "Cost"=$Cost.Sum; "Resource"=$Resource})
    }
}

Disconnect-AzAccount

$EndTime = (Get-date)
$runtime = New-TimeSpan –Start $StartTime –End $EndTime

Write-host "[" $EndTime.ToString('yyyy-MM-dd HH:mm:ss') "]...Job is finished" -ForegroundColor Green
Write-host "Start time is" $StartTime.ToString('yyyy-MM-dd HH:mm:ss') "`nEnd time is" $EndTime.ToString('yyyy-MM-dd HH:mm:ss') "`nTotal runtime is" $runtime
