<# Randy's Mod Consumer

    For the things you will see in this script, I apologize. It was the first in a long list. I promise I'm getting better.


9/7/21 - Version 1.2: 
    Fixed error allowing invalid mission date time to be uploaded
    Updated logic to move any uploaded zip to Archive before proceeding
#>


Function Clean-AutomationFolder {  
    foreach ($item in Get-ChildItem $FileLocation) {
        if ($item.name -ne "Archive" -and $item.extension -ne ".RECEIPT" -and $item.Name -ne "Modlists") 
            {
                echo $item.FullName
                Remove-Item (Get-ChildItem $item.FullName -recurse)
            }
        }

}

Start-Transcript -path "$($env:ARMAPATH)missions\HC Requests\Automation\Archive\RandysModConsumer.log" -append

$FileLocation = "$($env:ARMAPATH)missions\HC Requests\Automation"


<#

Testing dirs

Start-Transcript -path .\missions\iceberg_sideops\Automation\Archive\RandysModConsumer.log -append

$FileLocation = ".\missions\iceberg_sideops\Automation"

Stop-Transcript
#>

$TaskName = ""
$TaskSettings = ""
$TaskAction = ""
$TaskTrigger1 = ""
$DateCheck = ""

class HCRequest {
    [string]$ServerName
    [datetime]$DateStart
    [datetime]$DateStop;
  
    HCRequest(
        [string]$ServerName,
        [datetime]$DateStart,
        [datetime]$DateStop) {
      $this.ServerName = $ServerName
      $this.DateStart = $DateStart
      $this.DateStop = $DateStop
    }
  }

    #Validating JSON data

    try  
    {
        $FileName = (Get-ChildItem $FileLocation *.json) 
        $JSON = (Get-ChildItem $FileLocation *.json) | Get-Content | Convertfrom-Json
        $HCRequest = [HCRequest]::new($JSON.ServerName, $JSON.DateStart, $JSON.DateStop)
         
        # Move-Item $FileName.FullName -Destination "$ArchivePath\$($FileName.Name) uploaded $($currentDate)CST" -Force

    } catch {
        New-Item "$FileLocation\ERROR in $($FileName.Name).RECEIPT" -Force -Value $Error[0]
        $ErrorAction = 1
        }
#create the task name
    $TaskName = "Headless Client for $($HCRequest.ServerName) $($HCRequest.DateStart.ToString("yyyy-MM-dd HHmm") + " CST")"
          
#settings for run whether logged on or not
    $TaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable

#ACTIONS
    $TaskAction = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "Start-Arma3Server -launchID $($HCRequest.ServerName) -Port 2902 -modlistSelect Automatic -runType Client"

#TRIGGERS
    #Crafting the triggers
        try {
            Write-Host "Setting trigger"
            $TaskTrigger1 = New-ScheduledTaskTrigger -Once -At "$($HCRequest.DateStart)"
        } catch {
            New-Item "$FileLocation\ERROR when setting task trigger.RECEIPT" -Force -Value $Error[0]
            Clean-AutomationFolder
            Stop-Transcript
            Exit
        }

#create the start task
    try{
    Register-ScheduledTask -Action $TaskAction -TaskName "$TaskName" -TaskPath "\Arma3\HeadlessClientRequests\" -Trigger $TaskTrigger1 -Settings $TaskSettings -Force
    } catch {
    Clean-AutomationFolder
    Stop-Transcript
    Exit
    }

#create the stop task


#Check if task has been run; if so, disable
    try{
        $DateCheck = Get-ScheduledTaskInfo -TaskName "$TaskName" -TaskPath "\Arma3\HeadlessClientRequests\"
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

#Create the Receipt

$ReceiptFileName = "$TaskName ready.RECEIPT"

    try{ 
        New-Item -Path $FileLocation -Name $ReceiptFileName  -ItemType "File" -Force
    } catch {
        
    }
#CLEAR THE Automation FOLDER but Archive Folder and any Text reports

Write-host (Get-ScheduledTaskInfo -TaskName "$TaskName" -TaskPath "\Arma3\HeadlessClientRequests\").taskname

Clean-AutomationFolder

Stop-Transcript




Exit

