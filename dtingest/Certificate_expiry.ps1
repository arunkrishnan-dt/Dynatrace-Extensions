# PowerShell Script - dynatrace_ingest
#
# Script to send 'Days until SSL Certificate expiry' to Dynatrace
# 
# NOTE: Recommend using Dynatrace Synthetic capability for SSL certificate expiry checks where feasible 

# Set location of dynatrace_ingest utility
Set-Location "C:\Program Files\dynaTrace\oneagent\agent\tools"

## Urls to check 
$Urls = @(    
    "https://www.dynatrace.com/",
    "https://github.com/"
)

$currentTime=(Get-Date)

Foreach ($url in $Urls){

    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    try {
        $req = [Net.HttpWebRequest]::Create($url)
        $req.GetResponse() | Out-Null
        
        if ($req.GetResponse().StatusCode -eq "OK"){
            
            $absoluteUriReturned= $req.Address.AbsoluteUri
            $ExpirationDate = $req.ServicePoint.Certificate.GetExpirationDateString()        
    
            # Parse expiration date in dd/MM/yyyy format
            $regex_pattern = "(\d{1,2}/\d{1,2}/\d{4})" 
            $ExpirationDate -match $regex_pattern | Out-Null
            $day=$matches[1].Split('/')[0]
            $month=$matches[1].Split('/')[1]
            $year=$matches[1].Split('/')[2]
            if ($day.Length -eq 1){
                $day = "0"+$day
            }
            if ($month.Length -eq 1){
                $month = "0"+$month
            }
            $parsedExpirationDate=$day+"/"+$month+"/"+$year

            # parsedDate to PowerShell DateTime format
            $ExpDateToDT = [datetime]::ParseExact($parsedExpirationDate, "dd/MM/yyyy", $null)
            $DayCount = ($ExpDateToDT-$currentTime).TotalDays
            $DayCountRounded = [math]::Round($DayCount,0)

            # Uncomment to Debug
            # Write-Output "-------------------------------------"
            # Write-Output $url
            # Write-Output "Certificate Returned for: $absoluteUriReturned"
            # Write-Output "Expiry Date Returned: $ExpirationDate"
            # Write-Output "Parsed Expiry Date: $parsedExpirationDate"
            # Write-Output "Expiry Date to Date Time Format: $ExpDateToDT"            
            # Write-Output "Days Remaining: $DayCount"
            # Write-Output "-------------------------------------"        

            # Send Metric to Dyntrace
            Write-Output "dtingest_certificate_expiry_days_remaining,name=$url $DayCountRounded"  |  .\dynatrace_ingest.exe -v
            Write-Output "                                      "
        }        
    }
    catch {        
        Write-Host "Error reaching $url"
    }    
}


