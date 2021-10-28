

#create the task name
#this should be created via pulling in name of the pbo file in the uploaded folder
#something like: 
#$TaskName = Get-ChildItem D:\Arma3\servers\iceberg_sideop\mpmissions *.pbo
$TaskName = "Iceberg - SideOps"

#settings for run whether logged on or not
$TaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable

#sets the task to run as SYSTEM
#$TaskPrincipal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

#create the action, doesn't need to change
$TaskAction = New-ScheduledTaskAction -Execute "D:\Arma3\scripts\Iceberg Sideops\Iceberg Sideops - (Re)Launch - Date Aware.bat"

#create the triggers
#Pull this via name of modfile
$TaskTrigger1 = (New-ScheduledTaskTrigger -Once -At "08/04/2021 18:30")
$TaskTrigger2 = (New-ScheduledTaskTrigger -Once -At "08/05/2021 6:30PM")
$TaskTrigger3 = (New-ScheduledTaskTrigger -Once -At "08/06/2021 6:30PM")

#create the task

Register-ScheduledTask -Action $TaskAction -TaskName "Iceberg - SideOps4" -TaskPath "\SideOps Schedules\" -Trigger $TaskTrigger1 -Settings $TaskSettings
 

#Check if task has been run; if so, disable
$DateCheck = Get-ScheduledTaskInfo -TaskName "$TaskName" -TaskPath "\SideOps Schedules\"



if ($DateCheck.NextRunTime -eq $null) {
    echo "null"

} else {
    echo "nope"
    echo "Next run time is "$DateCheck.NextRunTime 
    }

