<# Randy's Mod Consumer

    For the things you will see in this script, I apologize. It was the first in a long list. I promise I'm getting better.


9/7/21 - Version 1.2: 
    Fixed error allowing invalid mission date time to be uploaded
    Updated logic to move any uploaded zip to Archive before proceeding
#>


Function Clean-AutomationFolder {  
    foreach ($item in Get-ChildItem $FileLocation) {
        if ($item.name -ne "Archive" -and $item.extension -ne ".txt" -and $item.Name -ne "Modlists") 
            {
                echo $item.FullName
                Remove-Item $item.FullName -recurse -Force
            }
        }

}

Start-Transcript -path "$($env:ARMAPATH)missions\iceberg_sideop\Automation\Archive\RandysModConsumer.log" -append



$SideOpsMissionDir = "$($env:ARMAPATH)Missions\iceberg_sideop"
$FileLocation = "$($env:ARMAPATH)missions\iceberg_sideop\Automation"
$ArchivePath = "$($env:ARMAPATH)missions\iceberg_sideop\Automation\Archive"
$SideOpsModlistDir = "$($env:ARMAPATH)configs\iceberg_sideop"

$currentDate = (Get-Date -format 'yyyyMMdd_hhmm')

$TaskName = ""

$TaskSettings = ""

$TaskAction = ""

$ModlistFileName = ""
$Date = ""
$Time = ""
$TaskTrigger1 = ""
$DateCheck = ""

<#Pull data from upload
    Upload ZIP file as "SideOps.zip"
    Scheduled process runs every minute? Research best, low cost, way to do this. "Script run when file added to directory"
    Files inside zip should be formatted as needed below
    CHECK Create new directory as "PBOname" and extract files to
        Following scripts use $FileLocation set by detected script
            CHECK Zip file is archived, other files placed in needed locations:
                  Modlist > D:\Arma3\configs\iceberg_sideop
                  Mission file > D:\Arma3\missions\iceberg_sideop\
    Text file placed in upload location with:
        "Success: Date-Time-MissionName"
        "No PBO found in"
    #>

<# CLEAR THE Automation FOLDER
    
    foreach ($item in Get-ChildItem $FileLocation) {
        if ($item.name -ne "Archive") 
            {
            echo $item.FullName
          # Remove-Item $item.FullName -recurse -Force
            }
        }
    


#>



#Pull ZIP file from $FileLocation and extract to temp folder
   $ZipFileName = ""
   $ZipFileDirName = ""
   $TaskName = ""

    
   $ZipFileName = (Get-ChildItem $FileLocation *.zip)
    $ZipFileDirName = $ZipFileName.FullName.Split(".",2)[0]
    Expand-Archive "$FileLocation\$ZipFileName" -DestinationPath "$ZipFileDirName"
    
    Move-Item $ZipFileName.FullName -Destination "$ArchivePath\$ZipFileName uploaded $($currentDate)CST" -Force
        

#Checking if ZIP file has requisite mods
    #Moves mods if so
    #Ends script if no, with error file
    

        $ErrorAction = ""

        try  
        {
                Test-Path (Get-ChildItem $ZipfileDirname\modlist*.* -Recurse)
                $ModlistFileSize = Get-ChildItem $ZipfileDirname\modlist*.* -Recurse
                Write-Host There is a modfile. It is $ModlistFileSize.Length bits. The limit is 6500. 
                    if ($ModlistFileSize.Length -ge 6500) {
                        New-Item "$FileLocation\$ZipFileName is too large.txt" -Force
                    }                   
        } catch {
            New-Item "$FileLocation\RECEIPT NoModFileFound or invalid format in $ZipFileName.txt" -Force
            $ErrorAction = 1
            }
        if (Test-Path (Get-ChildItem $ZipfileDirname\*.pbo -Recurse)) 
        {
            $MissionFileName = (Get-ChildItem $ZipFileDirName\*.pbo -Recurse)
            Write-Host There is a Mission File.                        
        } else {
            New-Item "$FileLocation\RECEIPT NoPBOFound in $ZipFileName.txt" -Force
            $ErrorAction = 1
            } 

        if ($ErrorAction -eq 1){
            Write-Host oh shit
            Stop-Transcript
            Exit
            }

#create the task name
    #this should be created via pulling in name of the pbo file in the uploaded folder
    #something like: 
        $TaskName = (Get-ChildItem $ZipFileDirName *.pbo).Name.Split(".",2)[0] + " on " + (Get-ChildItem $ZipfileDirname modlist*.*).Name.Split("_",2)[-1]
        $ReceiptName = (Get-ChildItem $ZipFileDirName *.pbo).Name.Split(".",2)[0]


              

#settings for run whether logged on or not
    $TaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable

#sets the task to run as SYSTEM
    #$TaskPrincipal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

#ACTIONS
    #Make new script to use new date time function OR cconvert modlist string to have no time
    $TaskAction = New-ScheduledTaskAction -Execute "$($env:ARMAPATH)scripts\Iceberg Sideops\Iceberg Sideops - (Re)Launch - Date Aware.bat"

#TRIGGERS
    #Pull this via name of modfile
        #The path will need to be the path inside the upload directory
        #FORMAT: modlist_YYYY_MM_DD_HH_MM.txt
        $ModlistFileName = Get-ChildItem $ZipfileDirname modlist*.* | Split-Path -leaf
        $Date = $ModlistFileName.Substring(8,10).Replace("_","/")
        $Time = $ModlistFileName.Substring(19,5).Replace("_",":")
        

    #Crafting the triggers
        try {
        Write-Host "Setting trigger"
        $TaskTrigger1 = New-ScheduledTaskTrigger -Once -At "$Date $Time"
        } catch {
        New-Item -Path $FileLocation -Name "RECEIPT $TaskName has invalid date or time, verify the modlist $ReceiptDate $ReceiptTime CST.txt" -ItemType "File" -ErrorAction Ignore
        Clean-AutomationFolder
        Stop-Transcript
        Exit
        }
    #Generating the Time of trigger for receipt
        $ReceiptDate = $Date.Replace("/","")   
        $ReceiptTime = $Time.Replace(":","")
       

#create the task
    try{
    Register-ScheduledTask -Action $TaskAction -TaskName "$TaskName" -TaskPath "\SideOps Schedules\" -Trigger $TaskTrigger1 -Settings $TaskSettings -Force
    } catch {
    Clean-AutomationFolder
    Stop-Transcript
    Exit
    }
<# #######################  No longer needed with try logic ###################

#Validate the task was created. If not, clean up and return error text file
    $invalidMissionTime = @()
    Get-ScheduledTask -TaskName "$TaskName" -ErrorVariable invalidMissionTime
    
        if ($invalidMissionTime.Count -gt 0) 
            {
            New-Item -Path $FileLocation -Name "$TaskName has invalid date or time, verify the modlist $ReceiptDate $ReceiptTime CST.txt" -ItemType "File"
                #cleanup, then exit
                foreach ($item in Get-ChildItem $FileLocation) {
                    if ($item.name -ne "Archive" -and $item.extension -ne ".txt" -and $item.Name -ne "Modlists") 
                        {
                            echo $item.FullName
                            Remove-Item $item.FullName -recurse -Force
                        }
                    }
            exit
            }
#>

#Check if task has been run; if so, disable
    try{
        $DateCheck = Get-ScheduledTaskInfo -TaskName "$TaskName" -TaskPath "\SideOps Schedules\"
            if ($DateCheck.NextRunTime -eq $null) {
                echo "null"
            } else {
                echo "Next run time is "$DateCheck.NextRunTime 
                }
    } catch {
    Clean-AutomationFolder
    Stop-Transcript
    Exit
    }
#Moving files to their place
    #Mission File
        Copy-Item -Path $MissionFileName.FullName -Destination $SideOpsMissionDir -ErrorAction Ignore
    #Modlist
        #modifying name to fit date-aware script
        $ModlistYYYYMMDD = $ModlistFileName.Substring(0,18) + ".txt"
        Copy-Item -Path "$ZipFileDirName\$ModlistFileName" -Destination "$SideOpsModlistDir\$ModlistYYYYMMDD" -ErrorAction Ignore

#Then we check for any updates to all mods

<#
$modlist = Get-Content (Get-ChildItem $ZipfileDirname modlist*.*)

ForEach ($mod in $modlist) {
    $modnumber = $mod.Split("=")[-1]
    $modname = $mod.Split("=")[0]
    echo "DOWNLOADING $modname"
    Update-Arma3Mod -modNumber $modnumber 
    }
    #>
#Create the Receipt

$ReceiptFileName = "RECEIPT $ReceiptName ready on $ReceiptDate $ReceiptTime CST.txt"

    try{ 
        New-Item -Path $FileLocation -Name $ReceiptName  -ItemType "File"
        $Update = Update-Arma3ModBulk  "$SideOpsModlistDir\$ModlistYYYYMMDD" -OutputRequired| Out-String | Add-Content "$FileLocation\$ReceiptFileName"
    } catch {
        New-Item -Path $FileLocation -Name "RECEIPT $ReceiptName already set for $ReceiptDate $ReceiptTime CST.txt" -ItemType "File" -ErrorAction Ignore
    }
#CLEAR THE Automation FOLDER but Archive Folder and any Text reports

Write-host (Get-ScheduledTaskInfo -TaskName "$TaskName" -TaskPath "\SideOps Schedules\").taskname

Clean-AutomationFolder

Stop-Transcript




Exit

