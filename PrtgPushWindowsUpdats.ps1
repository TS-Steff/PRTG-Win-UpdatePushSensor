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
[cmdletbinding()]
param(
    [Parameter(Mandatory=$false)] [string]$probeIP = "http://127.0.0.1", # include https or http
    [Parameter(Mandatory=$false)] [string]$sensorPort = "5050", # 5050 http / 5051 https
    [Parameter(Mandatory=$false)] [string]$sensorKey = "KEY",
    [Parameter(Mandatory=$false)] [string[]]$ignoreKBs = @('2267602x'), #for example Security Intelligence-Update for Defender KB226602
	[Parameter(Mandatory=$false)] [switch]$DryRun = $false
)


<#
####
# CONFIG START
####
$probeIP = "PROBE"  #include https or http
$sensorPort = "PORT"
$sensorKey ="KEY"
$ignoreKBs = @('2267602x') #for example Security Intelligence-Update for Defender KB226602

####
# CONFIG END
####
#>

### Update Defender Signature
Update-MpSignature

$updHid = 0
$updCri = 0
$updOpt = 0
$updCriText = ""

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
       -URI ($probeIP + ":" + $sensorPort + "/" + $sensorKey) `
       -ContentType "text/xml" `
       -Body $prtgresult `
       -usebasicparsing

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
        if($ignoreKBs -contains $update.KBArticleIDs -eq $false){
            write-verbose "no ignores"
            $updCri += 1
            $updCriText += "KB" + $update.KBArticleIDs + " "
        }else{
            $verbosMsg = "KB" + $update.KBArticleIDs + " will be ignored"
            write-verbose "$verbosMsg"
        }

    }else{
        $updOpt += 1
    }
}

write-verbose "hidden: $updHid" 
write-verbose "critical: $updCri" 
write-verbose "optional: $updOpt" 


# Get days since last update
$KeyValue = get-hotfix | sort-object -Descending -Property InstalledOn -ErrorAction SilentlyContinue | Select-Object -First 1
$LastUpdate = $KeyValue.InstalledOn
$LastUpdateDate = Get-Date $LastUpdate -Format "yyyy-MM-dd"
$now = (Get-Date).toString("yyyy-MM-dd")
$diffSinceLastUpdate = New-TimeSpan -Start $LastUpdateDate -End $now
$diffSinceLastUpdate = $diffSinceLastUpdate.Days

write-verbose "days: $diffSinceLastUpdate" 
if($rebootPending -eq 1){
    $diffSinceLastUpdate = 0
}

 
$prtgresult += @"
    <result>
        <channel>Reboot pending</channel>
        <LimitMaxError>0.5</LimitMaxError>
        <value>$rebootPending</value>
	  <valueLookup>ts.WinPushWindowsUpdates</valueLookup>
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
    <text>Critical: $updCriText </text>
</prtg>

"@

#sendPush

if($DryRun){
    write-host $prtgresult
}else{
    sendPush
}