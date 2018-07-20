

 
$URL= "https://Dtekex2013-s3.dtek.com/owa"
$Domain = "DTEK.COM"

#// user list 
 $Username="Danny-adm"
 $Password="Popeye44"


#Initialize default values
$Result = $False
$StatusCode = 0
$Latency = 0
$Username = $Domain + "\" + $Username
try{
#########################
#Work around to Trust All Certificates is is from this post
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
       }
   }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#Initialize Stop Watch to calculate the latency.
$StopWatch = [system.diagnostics.stopwatch]::startNew()
#Invoke the login page
$Response = Invoke-WebRequest -Uri $URL -SessionVariable owa
#Login Page - Fill Logon Form
if ($Response.forms[0].id -eq "logonform") {
$Form = $Response.Forms[0]
$Form.fields.username= $Username
$form.Fields.password= $Password
$authpath = "$URL/auth/owaauth.dll"
#Login to OWA
$Response = Invoke-WebRequest -Uri $authpath -WebSession $owa -Method POST -Body $Form.Fields
#SuccessfulLogin 
if ($Response.forms[0].id -eq "frm") {
  #Retrieve Status Code
  $StatusCode = $Response.StatusCode
  # Logoff Session
  $logoff = "$URL/auth/logoff.aspx?Cmd=logoff&src=exch"
  $Response = Invoke-WebRequest -Uri $logoff -WebSession $owa
  #Calculate Latency
  $StopWatch.stop()
  $Latency = $StopWatch.Elapsed.TotalSeconds
  $Result = $True
}
#Fill Out Language Form, if it is first login
elseif ($Response.forms[0].id -eq "lngfrm") {
  $Form = $Response.Forms[0]
  #Set Default Values
  $Form.Fields.add("lcid",$Response.ParsedHtml.getElementById("selLng").value)
  $Form.Fields.add("tzid",$Response.ParsedHtml.getElementById("selTZ").value)
  $langpath = "$URL/lang.owa"
  $Response = Invoke-WebRequest -Uri $langpath -WebSession $owa -Method $form.Method -Body $form.fields
  #Retrieve Status Code
  $StatusCode = $Response.StatusCode
			
# Logoff Session
# $logoff = "$URL/auth/logoff.aspx?Cmd=logoff&src=exch"
# $Response = Invoke-WebRequest -Uri $logoff -WebSession $owa
			
  #Calculate Latency
  $StopWatch.stop()
  $Latency = $StopWatch.Elapsed.TotalSeconds
  $Result = $True
}
elseif ($Response.forms[0].id -eq "logonform") {
  #We are still in LogonPage
  #Retrieve Status Code
  $StatusCode = $Response.StatusCode
  #Calculate Latency
  $StopWatch.stop()
  $Latency = $StopWatch.Elapsed.TotalSeconds
  $Result = "Failed to logon $username. Check the password or account."
}
}
}
#Catch Exception, If any
catch
{
  #Retrieve Status Code
  $StatusCode = $Response.StatusCode
  if ($StatusCode -notmatch '\d\d\d') {$StatusCode = 0}
  #Calculate Latency
  $StopWatch.stop()
  $Latency = $StopWatch.Elapsed.TotalSeconds
  $Result = $_.Exception.Message
}
#Display Results
Write-Host "Status Code: $StatusCode`nResult: $Result`nLatency: $Latency Seconds"