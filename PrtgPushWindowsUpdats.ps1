<#

.NOTES
┌─────────────────────────────────────────────────────────────────────────────────────────────┐ 
│ ORIGIN STORY                                                                                │ 
├─────────────────────────────────────────────────────────────────────────────────────────────┤ 
│   DATE        : 2019.04.04                                                                  |
│   AUTHOR      : TS-Management GmbH, Stefan Müller                                           | 
│   DESCRIPTION : PRTG Windows Update Minimal Push Script                                     |
└─────────────────────────────────────────────────────────────────────────────────────────────┘
#>

####
# CONFIG START
####
$probeIP = "10.4.4.116"
$sensorPort = "5050"
$sensorKey ="0F126019-CDAB-4246-9A9E-C9937CC216A6"

####
# CONFIG END
####

$updHid = 0
$updCri = 0
$updOpt = 0

$rebootPending = 0
$prtgresult = @"
<?xml version="1.0" encoding="UTF-8" ?>
<prtg>

"@

function sendPush(){
    Add-Type -AssemblyName system.web

    write-host "result"-ForegroundColor Green
    write-host $prtgresult 

    #$Answer = Invoke-WebRequest -Uri $NETXNUA -Method Post -Body $RequestBody -ContentType $ContentType -UseBasicParsing
    $Answer = Invoke-WebRequest `
       -method POST `
       -URI ("http://" + $probeIP + ":" + $sensorPort + "/" + $sensorKey) `
       -ContentType "text/xml" `
       -Body $prtgresult `
       -usebasicparsing

       #-Body ("content="+[System.Web.HttpUtility]::UrlEncode.($prtgresult)) `
    #http://10.4.4.116:5055/637D334C-DCD5-49E3-94CA-CE12ABB184C3?content=<prtg><result><channel>MyChannel</channel><value>10</value></result><text>this%20is%20a%20message</text></prtg>   
    if ($answer.statuscode -ne 200) {
       write-warning "Request to PRTG failed"
       exit 1
    }
    else {
       $answer.content
    }
}

# Check if a reboot is pending
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"){
    $rebootPending = 1
}



# Get pending Updates
$updateSession = New-Object -com "Microsoft.Update.Session"
$updates=$updateSession.CreateupdateSearcher().Search(("IsInstalled=0 and Type='Software'")).Updates

foreach ($update in $updates){

    if ($update.IsHidden){
        $updHid += 1
    }elseif($update.AutoSelectOnWebSites){
        $updCri += 1
    }else{
        $updOpt += 1
    }
}

write-host "hidden: " $updHid
write-host "critical: " $updCri
write-host "optional: " $updOpt




# Get days since last update
$KeyValue = get-hotfix | sort-object -Descending -Property InstalledOn -ErrorAction SilentlyContinue | Select-Object -First 1
$LastUpdate = $KeyValue.InstalledOn
$LastUpdateDate = Get-Date $LastUpdate -Format "yyyy-MM-dd"
$now = (Get-Date).toString("yyyy-MM-dd")
$diffSinceLastUpdate = New-TimeSpan -Start $LastUpdateDate -End $now
$diffSinceLastUpdate = $diffSinceLastUpdate.Days

write-host "days: " $diffSinceLastUpdate
if($rebootPending -eq 1){
    $diffSinceLastUpdate = 0
}

 
$prtgresult += @"
    <result>
        <channel>Reboot pending</channel>
        <LimitMaxWarning>0.5</LimitMaxWarning>
        <value>$rebootPending</value>
        <showChart>1</showChart>
        <showTable>1</showTable>
        <LimitWarningMsg>Reboot pending</LimitWarningMsg>
        <LimitMode>1</LimitMode>
    </result>
    <result>
        <channel>Win Upd State</channel>
        <unit>Custom</unit>
        <CustomUnit>d</CustomUnit>
        <LimitMaxWarning>30</LimitMaxWarning>
        <LimitMaxError>60</LimitMaxError>
        <value>$diffSinceLastUpdate</value>
        <showChart>1</showChart>
        <showTable>1</showTable>
        <LimitWarningMsg>Windows Update older then 30 days</LimitWarningMsg>
        <LimitErrorMsg>Windows Update older then 60 days</LimitErrorMsg>
        <LimitMode>1</LimitMode>
    </result>
    <result>
        <channel>Critical Updates</channel>
        <unit></unit>
        <value>$updCri</value>
        <showChart>1</showChart>
        <showTable>1</showTable>
        <LimitMaxWarning>0</LimitMaxWarning>
        <LimitMaxError>1</LimitMaxError>
    </result>
    <result>
        <channel>Optional Updates</channel>
        <unit></unit>
        <value>$updOpt</value>
        <showChart>1</showChart>
        <showTable>1</showTable>
    </result>
    <result>
        <channel>Hidden Updates</channel>
        <unit></unit>
        <value>$updHid</value>
        <showChart>1</showChart>
        <showTable>1</showTable>
    </result>
</prtg>

"@

sendPush

