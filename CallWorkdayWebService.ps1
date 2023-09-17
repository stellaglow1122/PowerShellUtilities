$uri = $WorkdayWebserivceEndpoint
$date = get-date
$entryTime = $date.AddHours(-8).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fff-08:00')

foreach ($WID in $CourseWIDs) {
    $xml = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<env:Envelope
xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
<env:Header>
<wsse:Security env:mustUnderstand="1">
    <wsse:UsernameToken>
        <wsse:Username>$WorkdayUsername</wsse:Username>
        <wsse:Password
            Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">$WorkdayPassword</wsse:Password>
    </wsse:UsernameToken>
</wsse:Security>
</env:Header>
<env:Body>
<wd:Get_Learning_Enrollments_Request xmlns:wd="urn:com.workday/bsvc" wd:version="v39.2">
    <wd:Request_Criteria>
        <wd:Learning_Content_Reference>
            <wd:ID wd:type="WID" >$WID</wd:ID>
        </wd:Learning_Content_Reference>
    </wd:Request_Criteria>
    <wd:Response_Filter>
        <wd:Page>1</wd:Page>
        <wd:Count>999</wd:Count>
        <wd:As_Of_Entry_DateTime>$entryTime</wd:As_Of_Entry_DateTime>
    </wd:Response_Filter>
</wd:Get_Learning_Enrollments_Request>
</env:Body> 
</env:Envelope>
"@
    try {
        $tryCnt = 0
        do {
            try {
                $post = Invoke-WebRequest -Uri $uri -Method Post -Body $xml -ContentType "application/xml" -TimeoutSec 0 -UseBasicParsing -DisableKeepAlive
                [xml]$XmlDocument = $post.Content
            }
            catch {
                $tryCnt++
                Start-Sleep -Seconds 10
            }
        } while ( $tryCnt -lt 3 -and -not $XmlDocument)

        if ( -not $XmlDocument ) {
            throw "Failed to get response from WorkDay web service $uri"
        }
    }
    catch {
        Write-Verbose 'Exception thrown!'
        throw $_
    }
    $totalPages = $XmlDocument.Envelope.Body.Get_Learning_Enrollments_Response.Response_Results.Total_Pages

    for ($i = 1; $i -le $totalPages; $i++) {
        $xml = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<env:Envelope
xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
<env:Header>
<wsse:Security env:mustUnderstand="1">
    <wsse:UsernameToken>
        <wsse:Username>$WorkdayUsername</wsse:Username>
        <wsse:Password
            Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">$WorkdayPassword</wsse:Password>
    </wsse:UsernameToken>
</wsse:Security>
</env:Header>
<env:Body>
<wd:Get_Learning_Enrollments_Request xmlns:wd="urn:com.workday/bsvc" wd:version="v39.2">
    <wd:Request_Criteria>
        <wd:Learning_Content_Reference>
            <wd:ID wd:type="WID" >$WID</wd:ID>
        </wd:Learning_Content_Reference>
    </wd:Request_Criteria>
    <wd:Response_Filter>
        <wd:Page>$i</wd:Page>
        <wd:Count>999</wd:Count>
        <wd:As_Of_Entry_DateTime>$entryTime</wd:As_Of_Entry_DateTime>
    </wd:Response_Filter>
</wd:Get_Learning_Enrollments_Request>
</env:Body> 
</env:Envelope>
"@
        try {
            $tryCnt = 0
            do {
                try {
                    $post = Invoke-WebRequest -Uri $uri -Method Post -Body $xml -ContentType "application/xml" -TimeoutSec 0 -UseBasicParsing -DisableKeepAlive
                    [xml]$XmlDocument = $post.Content
                }
                catch {
                    $tryCnt++
                    Start-Sleep -Seconds 10
                }
            } while ( $tryCnt -lt 3 -and -not $XmlDocument )

            if ( -not $XmlDocument ) {
                throw "Failed to get response from WorkDay web service $uri"
            }

        }
        catch {
            Write-Verbose 'Exception thrown!'
            throw $_
        }
        # Get enrollment data for each enrollment
        $enrollmentDatas = $XmlDocument.Envelope.Body.Get_Learning_Enrollments_Response.Response_Data.Learning_Enrollment.Learning_Enrollment_Data
        Append-Log "Now checking course WID $WID for page $i"
        foreach ($enrollmentData in $enrollmentDatas) {
    
            $completionDate = $enrollmentData.Learning_Enrollment_Completion_Date
            if ($completionDate -ne $null) {
                # Get learner (worker number)
                $text = $enrollmentData.Learner_Reference.ID.("#text")
                $workerID = $text[1]
                if (!$memberWorkerIDs.Contains($workerID)) {
                    try {
                        $userPrincipalName = (Get-Username -workerNumber $workerID).ToLower()
                    }
                    catch {
                        Append-Log "Failed to get username for $workerID"
                    }
                    try {
                        $objectID = (Get-AzureADUser -Filter "UserPrincipalName eq '$userPrincipalName'").ObjectId
                        Add-AzureADGroupMember -ObjectId $AADGroup -RefObjectId $objectID
                    }
                    catch {
                        Append-Log "Failed to add worker ID $workerID"
                    }
            
                }
        
            }
        }
    }
}
