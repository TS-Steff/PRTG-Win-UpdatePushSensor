# PRTG-WindowsUpdatePushSensor
*This project is as it is*

## Description
I had problems getting the integrated Windows Update Sensor to work from domain joined probes to non joined servers.
This script should be run as a task every 12 or 24 hours.

The scripts pushes the followin information to a *HTTP Push Data Advanced* sensor on the probe:
- Reboot pending
- Last Update date
- number of critical updates to be installed
- number of optional updates to be installed
- number of hidden updates

## Parameters
| parameter | example                                   | type    | mandatory | default          | description
|:----------|:------------------------------------------|:--------|:----------|:-----------------|:------
| probeIP   | http://127.0.0.1                          | string  | false     | http://127.0.0.1 | the ip of the probe wehere the push sensor is
| sensorPort| 5050                                      | string  | false     | 5050             | 5050 default http / 5051 default https
| sensorKey | ``B386C8BC-ECCD-4BC1-3AC7-29DF87EFE6EC``  | string  | **true**  | KEY              | the sensors key. this parameter has to be set!
| ignoreKBs | @('2267602x','3357560x')                  | string  | false     | @('2267602x')    | KB226602 = Security Intelligence-Update for Defender
| DryRun    | -DryRun $true                             | boolean | false     | $false           | does not send results to PRTG Probe


### WinTaskMgr-PrtgPushWindowsUpdate.xml
If you place the script in C:\Scripts\PrtgPushWindowsUpdats.ps1 you can import the task and save. Makr sure to enter correct credentials.
