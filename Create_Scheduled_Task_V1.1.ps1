

$FileLocation = "D:\Arma3\missions\iceberg_sideop\Automation\"

$TaskName = ""

$TaskSettings = ""

$TaskAction = ""

$ModlistFileName = ""
$Date = ""
$Time = ""
$TaskTrigger1 = ""
$DateCheck = ""

#create the task name
    #this should be created via pulling in name of the pbo file in the uploaded folder
    #something like: 
        $TaskName = (Get-ChildItem $FileLocation *.pbo).Name.Split(".",2)[0]
                #$TaskName = Get-ChildItem D:\Arma3\servers\iceberg_sideop\mpmissions *.pbo
                #$TaskName = "Iceberg - SideOps"

#settings for run whether logged on or not
    $TaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable

#sets the task to run as SYSTEM
    #$TaskPrincipal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

#ACTIONS
    #Make new script to use new date time function OR cconvert modlist string to have no time
    $TaskAction = New-ScheduledTaskAction -Execute "D:\Arma3\scripts\Iceberg Sideops\Iceberg Sideops - (Re)Launch - Date Aware.bat"

#TRIGGERS
    #Pull this via name of modfile
        #The path will need to be the path inside the upload directory
        #FORMAT: modlist_YYYY_MM_DD_HH_MM.txt
        $ModlistFileName = Get-ChildItem $FileLocation modlist*.* | Split-Path -leaf
        $Date = $ModlistFileName.Substring(8,10).Replace("_","/")
        $Time = $ModlistFileName.Substring(19,5).Replace("_",":")
    #Crafting the triggers
        $TaskTrigger1 = (New-ScheduledTaskTrigger -Once -At "$Date $Time")


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

