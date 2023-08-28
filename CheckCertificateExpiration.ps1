[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$URLs = @("URLs to check if certificate is expired")
foreach ($url in $URLs)
{
    $req = ""
    $req = [Net.HttpWebRequest]::Create($url)
    try
    {
        $req.GetResponse() | Out-Null
        $expirationDate = ""
        $expirationDate = $req.ServicePoint.Certificate.GetExpirationDateString()
        
        $SqlCmd.ExecuteNonQuery()
        $Cert = $null
        $Cert = [Security.Cryptography.X509Certificates.X509Certificate2]$req.ServicePoint.Certificate.Handle
        $SANList = $null
        $SANList = ($Cert.Extensions | Where-Object {$_.Oid.Value -eq "2.5.29.17"})
        if ($SANList -ne $null)
        {
            $SANList = $SANList.Format(0) -split ", "
            
            foreach($SAN in $SANList)
            {
                write-host "$SAN is under $url"
            }
        }

        if ((get-date) -gt ([DateTime]$expirationDate).AddDays(-30))
        {
            #$str = $req.ServicePoint.Certificate.GetName()
            #$issueTo = $str.substring($str.IndexOf('CN=') + 3, $str.IndexOf('E=') - $str.IndexOf('CN=') - 5)
            write-host "$url is goint to expire in 30 days"
        }
    }
    catch [Net.WebException]
    {
        Write-Host "URL $url failed to get the certificate"
    }
}
