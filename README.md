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

You'll have to edit the script config section for your envirement

### WinTaskMgr-PrtgPushWindowsUpdate.xml
If you place the script in C:\Scripts\PrtgPushWindowsUpdats.ps1 you can import the task and save. Makr sure to enter correct credentials.
