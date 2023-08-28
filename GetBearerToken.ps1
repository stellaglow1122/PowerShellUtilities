function Get-BearerToken 
{
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        # Consumer key
        [Parameter()]
        [string] 
        $ConsumerKey = 'ComsumerKey',
        
        # Consumer secret
        [Parameter()]
        [string]
        $ConsumerSecret = 'ComsumerSecret'
    )
        
    try {
        Write-Verbose 'Preparing call uri'
        $uri = "Host URL"
        Write-Verbose "Endpoint is: $uri"
        
        Write-Verbose 'Building base64 credential'
        $credential = [Convert]::ToBase64String( [System.Text.Encoding]::UTF8.GetBytes("$($ConsumerKey):$($ConsumerSecret)") )
        Write-Verbose 'Success!'
        
        $tryCnt = 0
        Write-Verbose 'Trying up to three times to get a bearer token from endpoint'
        do {
            try {
                Write-Verbose "Invoking request to endpoint for bearer token ( try $tryCnt )"
                $response = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Headers @{"Authorization" = "Basic $credential"} -Body @{"grant_type" = "client_credentials"} -UseBasicParsing
                Write-Verbose 'Success!'
                Write-Verbose "Status Code: $( $response.StatusCode )"
                Write-Verbose "Content: $( $response.Content )"
                $result = ( $response.Content | ConvertFrom-Json ).access_token
            }
            catch {
                Write-Verbose 'Exception thrown!'
                Write-Verbose "Status Code: $($_.Exception.Response.StatusCode)"
                Write-Verbose "Content:`r`n$content"
                            
                $tryCnt++
                Start-Sleep -Seconds 10
            }
        } while ( $tryCnt -lt 3 -and -not $result )
        
        if ( -not $result ) {
            throw "Failed to retrieve bearer token from endpoint $uri"
        }
        return $result
        
    }
    catch {
        Write-Verbose 'Exception thrown!'
        throw $_
    }
}
