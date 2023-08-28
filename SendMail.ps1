Function SendMail
{ 
    param(
        [string] $P_subject = "Please input the email subject",
        [string] $P_text = "Please input email body / test message",
        [string] $P_sender = "",
        [string] $P_recipent = "",
        [string] $P_cclist = ""
      )
    
    #Additional message for this script
    $P_text = "<style>             
                   body {font-family: Calibri; font-size: 10pt;}
                   table, th, td {border: 1px solid black; border-collapse: collapse; padding: 10px;}
                   th {background-color: #0f79eb; color: #FFFFFF;}
                   table {vertical-align: middle;}
               </style><br> " + $P_text


    #Orignal Send Mail Code
    $MailMessage = New-Object System.Net.Mail.MailMessage 
    $SMTPClient = New-Object System.Net.Mail.smtpClient 
    $SMTPClient.host = "Your SMTP Server"
    $MailMessage.IsBodyHtml=$true
    $MailMessage.Sender = $P_sender
    $MailMessage.From = $P_sender
    $MailMessage.Subject = $P_subject    
    $MailMessage.To.add($P_recipent)
    if ($P_cclist -ne "")
    {
        $MailMessage.CC.add($P_cclist)
    }
    $MailMessage.Body = $P_text 
    $SMTPClient.Send($MailMessage)    
}
