# This is the function to get the status code of an url
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
function Get-UrlStatusCode([string] $Url)
{
    try 
    {
        $firstWebRequest = Invoke-Webrequest -uri $Url -TimeoutSec 90 -UseBasicParsing -UseDefaultCredential -DisableKeepAlive
        $firstWebRequest.statusCode
    }
    catch [Net.WebException]
    {
        [int]$_.Exception.Response.StatusCode
    }

}


# Read application list from database


foreach ($data in $DataSet.tables[0]) 
{
    $applicationName = $data['application_name']
    $applicationURL = $data['URL_name']
    $hostedServer = $data['server_name']
    $applicationPoolName = $data['appPool_name']
    $alert = $data['alert_on']
    $alertRecipientList = $data['alert_recipients']
    
    if ($alert -eq 1)
    {
        $statusCode = Get-UrlStatusCode $applicationURL
	    $applicationURL
        # If the status code is not equal to 200
        if ($statusCode -ne 200)
        {
		    # If the server is defined, not null
            if ($hostedServer -ne '')
            {
			    # Run the script on the remote server
			    # Use try & catch to ensure if login issue happens the remaining ones won't be affected.
			    write-host "Logging in to $hostedServer to restart application pool $applicationPoolName because $statusCode error is returned."
                try
                {
                    Invoke-Command -ComputerName $hostedServer -ScriptBlock{
                    Import-Module WebAdministration
			        # This is how we pass arguments into a invoke-command
                    $appPoolName = $using:applicationPoolName
			    
			        # Restart the application pool if it's not stopped, else just start it.
                    if ( (Get-WebAppPoolState -Name $appPoolName).Value -ne "Stopped" )
			        {
    		    	    Write-Host "Restarting the AppPool: $appPoolName"
			    	    Restart-WebAppPool -Name $appPoolName
			        }
			        else
			        {
					    Write-Host "AppPool was stopped, starting appPool now: $appPoolName"
					    Start-WebAppPool -Name $appPoolName
			        }
			    
			    
            
                    } -ArgumentList $applicationPoolName
                }
                catch
                {
                    $_.exception.gettype().fullname
                }
            }
        
            # Insert the error record to database

		    # This is the part to send notification if error detected.

        }
    }
    
}
