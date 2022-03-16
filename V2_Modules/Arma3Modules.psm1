#Arma3Modules


function Update-Arma3Mod {

<#
This module will use the provided mod number to gather the mod's last updated date.
Should the mod be unlisted, the web page will be scraped. Should anything change on Steam's side, this module will need to be updated to reflect.

Required input:

-ModNumber = The modnumber from the steam page.

Recommended to use in tandem with Get-Arma3ModDependencies
test
#>


#$modnumber = 2414840966
#$modnumber = 708250744
#$modnumber = 463939057 

    Param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $modNumber,


        [Parameter(Mandatory=$false)] #NoCheck is used in Bulk API processing
        [switch]$NoCheck

    )
    

    $modsLocation = "$($env:steamCMDPATH)steamapps\workshop\content\107410\"
    $steamCMD = "$($env:steamCMDPATH)"
    $timeUpdatedLocally = (get-childitem $modsLocation | where Name -EQ $modNumber).LastWriteTime.ToUniversalTime()

    if ($NoCheck) {
        cd $steamCMD
        .\steamcmd.exe +login iceberg_gaming_team +workshop_download_item 107410 $modnumber validate +quit
        Return
    }
        $xml = Invoke-RestMethod -uri 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/' -Method Post -Body "itemcount=1&publishedfileids[0]=$ModNumber"
     
        if ($xml.response.publishedfiledetails.time_updated -eq $null) {

            $modlistRaw = wget "https://steamcommunity.com/sharedfiles/filedetails/?id=$modNumber"

            if ($modlistRaw.Content | select-string -pattern '<title>Steam\sCommunity\s::\sError<\/title>') {
                #if at some point the mod no longer exists, as with ACEX = 708250744
             Return
            }else {

            $pulledOutput = ($modlistRaw.Content | select-string -pattern '<div class="detailsStatRight">(?<date>\D.*)@.(?<time>\d.*)<\/div>' -AllMatches).Matches[1]

            $timeUpdatedSteamUnparsed = $pulledOutput.Groups[1].Value + $pulledOutput.Groups[2].Value
       
        
            $timeUpdatedSteam = [datetime]"$timeUpdatedSteamUnparsed"
            }
        } else {
    
        $timeUpdatedSteam = (Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($xml.response.publishedfiledetails.time_updated))

        }
    

     CD $steamCMD #setting directory for steamCMD calls

    #Checking if mod exists at all
    if ($timeUpdatedLocally -eq $null) {
     Write-Output "$modNumber does not exist, downloaded on $(Get-Date)" | Add-Content $env:ARMAPATH\Scripts\Update_Log.txt
     Write-Host "$modNumber does not exist, downloading"
     .\steamcmd.exe +login iceberg_gaming_team +workshop_download_item 107410 $modnumber validate +quit

    } #Checking for the last updated date was today or day before 
    elseif ($timeUpdatedSteam -gt $timeUpdatedLocally) {
        Write-Output "$modNumber last updated on $timeUpdatedSteam, updated on $(Get-Date)"  | Add-Content $env:ARMAPATH\Scripts\Update_Log.txt
        #Checking if the mod has already been updated today
            Write-Output "Mod updating"
            #mod updated in steam, not updated locally yet, download mods
            CD $steamCMD
            .\steamcmd.exe +login iceberg_gaming_team +workshop_download_item 107410 $modnumber validate +quit
                
    } 
    else {
    Write-Output "$modNumber last updated on Steam on $timeUpdatedSteam, local update was $timeUpdatedLocally. No Update Needed."
    }
    
}

function Update-Arma3ModBulk {

<#
This module will use the provided mod list in full directory format to run single API call, and generate update responses off that.
Should the mod be unlisted, the web page will be scraped. Should anything change on Steam's side, this particular function will need to be updated to reflect.

Required input:

-ModNumber = The modnumber from the steam page.

Recommended to use in tandem with Get-Arma3ModDependencies
test
#>

  Param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $ModFile,
        [Parameter(Mandatory=$false)]
        [switch]$OutputRequired
    )

        
    $modsLocation = "$($env:steamCMDPATH)steamapps\workshop\content\107410\"
    $steamCMD = "$($env:steamCMDPATH)"

    $i=0
    $modlist = ""
    foreach ($mod in (Get-Content $ModFile)) 
        {
        #$mod= "fuccboi = 3127246032"
        $mod = $mod.Replace(" ","") #removing any whitespace
                        
        $modnumber = $mod.Split("=")[-1]
        $modname = $mod.Split("=")[0]
        $modlist += "&publishedfileids[$i]=$($modnumber)"
        $i+= 1
        }


        
$APIOutput= Invoke-RestMethod -uri 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/' -Method Post -Body "itemcount=$($i)$($modList)"



<#
Used in testing
$APIoutput = Invoke-RestMethod -uri 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/' -Method Post -Body "itemcount=1&publishedfileids[0]=1110082605"
$APIoutput = Invoke-RestMethod -uri 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/' -Method Post -Body "itemcount=1&publishedfileids[0]=2429902861"

/#>

$mod = $APIOutput.response.publishedfiledetails

foreach ($mod in $APIOutput.response.publishedfiledetails) {
    #Write-Host "Checking $($mod.publishedfileid)"
    $timeUpdatedLocally = ""
    $modnumber = $Mod.publishedfileid
    if ($mod.result -eq 9) { <#if result equals 9, then mod does not exist or is unlisted, therefore, we attempt to scrape directly#>
         $modlistRaw = wget "https://steamcommunity.com/sharedfiles/filedetails/?id=$modNumber"
        
        if ($modlistRaw.Content | select-string -pattern '<title>Steam\sCommunity\s::\sError<\/title>') {
            #if at some point the mod no longer exists, as with ACEX = 708250744
            write-host "no mod found for ID $($mod.publishedfileid)"
            Return

        } else {

            $pulledOutput = ($modlistRaw.Content | select-string -pattern '<div class="detailsStatRight">(?<date>\D.*)@.(?<time>\d.*)<\/div>' -AllMatches).Matches[1]
                if ($pulledOutput -eq $null) {
                    $pulledOutput = ($modlistRaw.Content | select-string -pattern '<div class="detailsStatRight">(?<date>\D.*)@.(?<time>\d.*)<\/div>' -AllMatches).Matches[0]
                }
            $timeUpdatedSteamUnparsed = $pulledOutput.Groups[1].Value + $pulledOutput.Groups[2].Value

            $timeUpdatedSteam = [datetime]"$timeUpdatedSteamUnparsed"
        }
    } else {
        $timeUpdatedSteam = (Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($mod.time_updated))
        
    }


        #Checking if mod exists at all on server
        if ((test-path "$($modsLocation)$($modnumber)") -eq $false) {
            Write-Output "$modNumber does not exist, downloaded on $(Get-Date)" | Add-Content $env:ARMAPATH\Scripts\Update_Log.txt
            Write-Host "$modNumber does not exist, downloading"
            cd $steamCMD
            .\steamcmd.exe +login iceberg_gaming_team +workshop_download_item 107410 $modnumber validate +quit

        } #Checking for the last updated date was today or day before 
               
        $timeUpdatedLocally = (get-childitem $modsLocation | where Name -EQ $modNumber).LastWriteTime.ToUniversalTime()

        if ($timeUpdatedSteam -gt $timeUpdatedLocally) {
            Write-Output "$modNumber last updated on $timeUpdatedSteam, updated on $(Get-Date)"  | Add-Content $env:ARMAPATH\Scripts\Update_Log.txt
            #Checking if the mod has already been updated today
                Write-Output "Mod updating"
                #mod updated in steam, not updated locally yet, download mods
                CD $steamCMD
                .\steamcmd.exe +login iceberg_gaming_team +workshop_download_item 107410 $modnumber validate +quit
                
        } 
        else {
        Write-Host "$modNumber last updated on Steam on $timeUpdatedSteam, local update was $timeUpdatedLocally. No Update Needed."

        if ($OutputRequired) {
            Write-Output "$modNumber last updated on Steam on $timeUpdatedSteam, local update was $timeUpdatedLocally. No Update Needed."
        }
        }
    
    

    }


}


function Get-Arma3ModDependencies {
<#
This module builds a modlist based on a shadowmod.

Required inputs:

-shadowModName = The name of the Shadowmod.
-shadowModNumber = The modnumber of the Shadowmod as per https://steamcommunity.com/sharedfiles/filedetails/?id=$shadowModNumber

Output will read as:

ModName=ModNumber
ModName=ModNumber
ModName=ModNumber

#>


#$shadowModName="17th Ranger Battalion Shadow Mod"
#$shadowModNumber=2414840966

    Param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $shadowModName,

        [Parameter(Mandatory=$true)]
        [string[]]
        $shadowModNumber
    )

    $modlist=""

$modlistRaw = wget https://steamcommunity.com/sharedfiles/filedetails/?id=$shadowModNumber
$modlistRaw.Content | out-file .\modlistRaw.txt

#if ((Get-Content .\modlist.txt) -join "`n" -match '<div class="requiredItemsContainer" id="RequiredItems">([\s\S]*)<!-- created by -->') { $matches[1] }

$pulledOutput = if ((Get-Content .\modlistRaw.txt) -join "`n" -match '<div class="requiredItemsContainer" id="RequiredItems">([\s\S]*)<!-- created by -->') { $matches[1] }

$pulledOutput | Out-File .\modlistextract.txt



$num=0
$runbit=0
$modlist = @("$shadowModName=$shadowModNumber") #adding the input shadow mod to the list
foreach ($line in (gc .\modlistextract.txt)) {
    #grab the link

    If ($runBit -ne 2) 
    {     
        if ($line -like '*https*') 
        {
        $modNumber = $line -replace '\D+(\d+)\D+','$1'
        $runBit += 1
        #Write-Host $runbit modNumber
        }

        if ($line -notlike '*</a*' -and $line -notlike '*<a*' -and $line -notlike '*<div class="requiredItem">*' -and $line -notlike $null)
        {
        $modName = $line -replace '\t+|</div>'
        $runBit += 1
        #Write-Host $runbit modName
        }
    } elseif ($runbit -eq 2 -and $modName -ne '')
    {
    
    #Write-Host $modName"="$modNumber
    $modlist += "$modName=$modNumber"
   
    $runbit = 0
    }
    
}
write-output $modlist
Remove-Item .\modlistRaw.txt
Remove-item .\modlistextract.txt
}


function Get-Arma3ModlistFormat {
<#
Obtains modlist for server based on 3 parameters
Will update old or missing mods

ServerModNames = Server Mods to be loaded for the server
LaunchID = Name of the server to launch
$modlistSelect = Sets the modlist to grab:
    Automatic - Pulls modlist.txt from $LaunchID directory
    DateAware - Pulls modlist_MM_DD_YYYY.txt from  #LaunchID directory
    SpecificModlist - Allows user to select modlist at time of run


$NoUpdate = Will not update mods
$Quiet = Will not show mod date information; only outputs modlist
$Bulk = Runs Bulk API check


#>
    Param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $ServerModNames,

        [Parameter(Mandatory=$true)]
        [string[]]
        $LaunchID,

        [Parameter(Mandatory=$true)]
        [string[]]
        $modlistSelect,

        [Parameter(Mandatory=$false)]
        [switch]$NoUpdate,
        
        [Parameter(Mandatory=$false)]
        [switch]$Quiet,
        
        [Parameter(Mandatory=$false)]
        [switch]$Bulk
    )

    #Determining the selection of the modlist

    $ModlistError
    $Modlist="$ServerModNames"
    if ($modlistSelect -eq "Automatic") 
        {
        $ModFile ="$($env:ARMAPATH)configs\$($LaunchID)\modlist.txt"
        }
    elseif ($modlistSelect -eq "DateAware") 
        {
        $ModFile="$($env:ARMAPATH)configs\$($LaunchID)\modlist_$Date.txt"
        }
    elseif ($modlistSelect -eq "SpecificModlist") 
        {
        $ModFile = Get-ChildItem $($env:ARMAPATH)configs\$LaunchID\modlist*.txt | Out-GridView -Title 'Choose your modlist' -PassThru | ForEach-Object { $_.FullName }
        }

    foreach ($mod in (Get-Content $ModFile)) 
        {
        #$mod= "fuccboi = 3127246032"
        $mod = $mod.Replace(" ","") #removing any whitespace
                        
        $modnumber = $mod.Split("=")[-1]
        $modname = $mod.Split("=")[0]
        $modlist += ";$repoPath$($modnumber)"

            if ($NoUpdate -or $Bulk){
            } elseif ($Quiet) {
                Update-Arma3Mod -modNumber $modnumber | Out-Null
            } else {
                Update-Arma3Mod -modNumber $modnumber
                }
        }
        
    if ($bulk) {
        Update-Arma3ModBulk -modfile $ModFile | Out-Null
    }
        
    <# DEPRECATED
    #Until a single mod can be downloaded, this script will die if mod is not found.
    If ($ModlistError -eq 1)
        {
        Write-Host "Missing mods, please address."
        $msgBoxInput = [System.Windows.MessageBox]::Show("Missing mods: $MissingMods",'Game input','OK','Error')
        Throw
        }
     
     #Testing
     #Write-Host $Modlist 
     #> 
     return $Modlist
}


function Start-Arma3Server {
<#
Start arma script

example: 

Start_Arma_V1.ps1 17th_operations 2302 Automatic

Input Parameters:
    LaunchID (This is the server name to set Config and Profile Data) ex: #17th_operations,17th_training
    Port ex: #2302,2402,2602,2702 
    ModlistType ex: #'Automatic','DateAware','SpecificModlist'
    RunType ex: Server, Client

Authored by Randy, with contributions from StackOverflow    

Required Modules:
function Get-Arma3ModlistFormat
function 


#Default Values for testing
$LaunchID="iceberg_persistent"
$Port="2302"
$modlistSelect="Automatic"


        [ValidatePattern("\AAutomatic\z|\ADateAware\z|\ASpecificModlist\z")]
#>

    Param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $launchID,

        [Parameter(Mandatory=$true)]
        [string[]]
        $Port,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Automatic", "DateAware", "SpecificModlist")]
        [string[]]
        $modlistSelect,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Server", "Client")]
        [string[]]
        $runType
    )

#Refreshes modules per any updates.

Import-Module -name 'C:\Program Files\WindowsPowerShell\Modules\Arma3Modules\Arma3Modules.psm1'


$Date = (Get-Date -Format yyyyMMdd)
$RepoPath=           "$($env:steamCMDPATH)steamapps\workshop\content\107410\"           #Mods location
$serverExeName=      "arma3server_x64.exe"                                         #64-bit version would be arma3server_x64.exe
$ArmaPath=           "$($env:ARMAPATH)servers\$LaunchID" #Executable location
$configPath=         "$($env:ARMAPATH)configs\$LaunchID"                         
$serverConfigPath=   "$($env:ARMAPATH)configs\$LaunchID\$($LaunchID)_server.cfg"   #Server Config File Path
$basicConfigPath=    "$($env:ARMAPATH)configs\$LaunchID\$($LaunchID)_basic.cfg"     #Basic Config File Path
$ProfilesPath=       "$($env:ARMAPATH)profiles\$LaunchID"                              #Profiles/Logs location


# Server Mods
if ( test-path $configPath\servermods.txt) {
    $ServerMods= (gc $configPath\servermods.txt) -join ";"
    } else {
    $ServerMods="@asm;@AdvancedTowing;@AdvancedSlingloading;@DisableBI"
    }

if ( test-path $configPath\HCmods.txt) {
    $HCMods= (gc $configPath\HCmods.txt) -join ";"
    } else {
    $HCMods="@asm"
    }

<#
#
#
#TEST VARIABLES#
$LaunchID="iceberg_cdlc"
$port=2302 #,2402,2602,2702
$modlistSelect="Automatic" #$args[2] #'Automatic','DateAware','SpecificModlist'
$runtype="Client"
$runtype="Server"
#
#
#>


    #Verifying no other sessions exist if server RunType

    if ($runtype -eq "Server") {
        $PriorityFilter="%$LaunchID\\arma3server_x64.exe"
        $processID = Get-WmiObject win32_process -filter "ExecutablePath LIKE `"$PriorityFilter`"" | Select-Object -expand processid
        $runningInstances = @(Get-WmiObject win32_process -filter "ExecutablePath LIKE `"$PriorityFilter`"")
        if ($runningInstances.Count -ne 0) 
        {
            $a = new-object -comobject wscript.shell 
            $intAnswer = $a.popup("There are " + $runningInstances.count + " instances running for $LaunchID. Kill? Timeout in 10 seconds",10,"Title",4)
            if ($intAnswer -eq 7) 
            {
            #exit
            } 
            else 
            {
            Stop-Process -id $processID
            #Get-Process -id $processID
            }
        }
    }


#Building the modlist, and checking for updates

$modlist = Get-Content "$($env:ARMAPATH)\configs\$($LaunchID)\modlist.txt" -raw
Write-Host ""
Write-Host "Loading and updating the following mods: "
Write-Host ""
Write-Host $modlist

if ($runType -eq "Client") {
    $ArmaMods = Get-Arma3ModlistFormat -ServerModNames $HCMods -modlistSelect $modlistSelect -LaunchID $LaunchID -Quiet -NoUpdate -ErrorAction Stop
	

} elseif ($runType -eq "Server") {
    $ArmaMods = Get-Arma3ModlistFormat -ServerModNames $ServerMods -modlistSelect $modlistSelect -LaunchID $LaunchID -Quiet -Bulk -ErrorAction Stop
}




#The final command

    $serverNameParameter = "-name=$LaunchID"
    $portParameter = "-port=$port"
    $client = "-client -connect=127.0.0.1"
    $passwordHC = "-password=$serverPassword"
    $serverExePath = Join-Path $ArmaPath $serverExeName
    $serverConfigParameter = '"-config=' + $(Resolve-Path $serverConfigPath) + '"'
    $basicConfigParameter = '"-cfg=' + $(Resolve-Path $basicConfigPath) +'"'
    $profilesParameter = '"-profiles=' + $(Resolve-Path $profilesPath) + '"'
    $performanceParameter = "-filePatching -autoInit -enableHT" #| -netlog 
    $nameHC="HC"
    $modsParameter = '"-mod=' + $($ArmaMods) + '"'


if ($runType -eq "Client") {
    $argumentList = @($serverNameParameter, $client, $passwordHC, $portParameter, $basicConfigParameter, $serverConfigParameter, $profilesParameter, $performanceParameter, $modsParameter, $nameHC)
} elseif ($runType -eq "Server"){
    $argumentList = @($serverNameParameter, $portParameter, $basicConfigParameter, $serverConfigParameter, $profilesParameter, $performanceParameter, $modsParameter)
}


Set-Location $ArmaPath

Write-Host "Starting server..."
Sleep 5

Start-Process  .\arma3server_x64.exe -ArgumentList $argumentlist -WindowStyle Minimized

#Setting priority of Executables to High
    
    $PriorityFilter="%$LaunchID\\arma3server_x64.exe"
    Get-WmiObject win32_process -filter "ExecutablePath LIKE `"$PriorityFilter`""| ForEach-Object { $_.SetPriority(128) }

Write-Host "Starting $runtype..."
Sleep 5


<#
-port=$Port 
"-config=$($CONFIGDATA)\$($LaunchID)_server.cfg 
-cfg=$($CONFIGDATA)\($LaunchID)_basic.cfg" 
-profiles=%PROFILEDATA% 
-name=%LAUNCHID% 
-filePatching 
-autoInit 
-enableHT 
-mod=$ArmaMods"


#start /min "iceberg_sideop" /realtime /affinity FF "D:\\arma3\\servers\\iceberg_sideop\\arma3server_x64.exe" -port=2702 -profiles=$($env:ARMAPATH)profiles\iceberg_sideop\ -name=HC%i "-mod=@asm;"

#>

}


function Stop-Arma3Server {
<#
Stop arma function



Input Parameters:
    LaunchID (This is the server name to set Config and Profile Data) ex: #17th_operations,17th_training
    Port ex: #2302,2402,2602,2702 
    ModlistType ex: #'Automatic','DateAware','SpecificModlist'
    RunType ex: Server, Client

Authored by Randy, with contributions from StackOverflow    

Required Modules:
function Get-Arma3ModlistFormat
function 


#Default Values for testing
$LaunchID="iceberg_cdlc"
$Port="2302"
$modlist="Automatic"


        [ValidatePattern("\AAutomatic\z|\ADateAware\z|\ASpecificModlist\z")]
#>

    Param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $launchID

    )



$Date = (Get-Date -Format yyyyMMdd)
$RepoPath=           "$($env:steamCMDPATH)steamapps\workshop\content\107410\"           #Mods location
$serverExeName=      "arma3server_x64.exe"                                         #64-bit version would be arma3server_x64.exe
$ArmaPath=           "$($env:ARMAPATH)servers\$LaunchID" #Executable location
$configPath=         "$($env:ARMAPATH)configs\$LaunchID"                         
$serverConfigPath=   "$($env:ARMAPATH)configs\$LaunchID\$($LaunchID)_server.cfg"   #Server Config File Path
$basicConfigPath=    "$($env:ARMAPATH)configs\$LaunchID\$($LaunchID)_basic.cfg"     #Basic Config File Path
$ProfilesPath=       "$($env:ARMAPATH)profiles\$LaunchID"                              #Profiles/Logs location




#Verifying no other sessions exist
    $PriorityFilter="%$LaunchID\\arma3server_x64.exe"
    $processID = Get-WmiObject win32_process -filter "ExecutablePath LIKE `"$PriorityFilter`"" | Select-Object -expand processid
    $runningInstances = @(Get-WmiObject win32_process -filter "ExecutablePath LIKE `"$PriorityFilter`"")
    if ($runningInstances.Count -ne 0) 
    {
        $a = new-object -comobject wscript.shell 
        $intAnswer = $a.popup("There are " + $runningInstances.count + " instances running for $LaunchID. Kill? Timeout in 5 seconds",5,"Title",4)
        if ($intAnswer -eq 7) 
        {
        #exit
        } 
        else 
        {
        Stop-Process -id $processID
        #Get-Process -id $processID
        }
    }
}



#Don't mind meeeeeee
function Write-Color {
    <#
	.SYNOPSIS
        Write-Color is a wrapper around Write-Host.
        It provides:
        - Easy manipulation of colors,
        - Logging output to file (log)
        - Nice formatting options out of the box.
	.DESCRIPTION
        Author: przemyslaw.klys at evotec.pl
        Project website: https://evotec.xyz/hub/scripts/write-color-ps1/
        Project support: https://github.com/EvotecIT/PSWriteColor
        Original idea: Josh (https://stackoverflow.com/users/81769/josh)
	.EXAMPLE
    Write-Color -Text "Red ", "Green ", "Yellow " -Color Red,Green,Yellow
    .EXAMPLE
	Write-Color -Text "This is text in Green ",
					"followed by red ",
					"and then we have Magenta... ",
					"isn't it fun? ",
					"Here goes DarkCyan" -Color Green,Red,Magenta,White,DarkCyan
    .EXAMPLE
	Write-Color -Text "This is text in Green ",
					"followed by red ",
					"and then we have Magenta... ",
					"isn't it fun? ",
                    "Here goes DarkCyan" -Color Green,Red,Magenta,White,DarkCyan -StartTab 3 -LinesBefore 1 -LinesAfter 1
    .EXAMPLE
	Write-Color "1. ", "Option 1" -Color Yellow, Green
	Write-Color "2. ", "Option 2" -Color Yellow, Green
	Write-Color "3. ", "Option 3" -Color Yellow, Green
	Write-Color "4. ", "Option 4" -Color Yellow, Green
	Write-Color "9. ", "Press 9 to exit" -Color Yellow, Gray -LinesBefore 1
    .EXAMPLE
	Write-Color -LinesBefore 2 -Text "This little ","message is ", "written to log ", "file as well." `
				-Color Yellow, White, Green, Red, Red -LogFile "C:\testing.txt" -TimeFormat "yyyy-MM-dd HH:mm:ss"
	Write-Color -Text "This can get ","handy if ", "want to display things, and log actions to file ", "at the same time." `
				-Color Yellow, White, Green, Red, Red -LogFile "C:\testing.txt"
    .EXAMPLE
    # Added in 0.5
    Write-Color -T "My text", " is ", "all colorful" -C Yellow, Red, Green -B Green, Green, Yellow
    wc -t "my text" -c yellow -b green
    wc -text "my text" -c red
    .NOTES
        Additional Notes:
        - TimeFormat https://msdn.microsoft.com/en-us/library/8kb3ddd4.aspx
    #>
    [alias('Write-Colour')]
    [CmdletBinding()]
    param (
        [alias ('T')] [String[]]$Text,
        [alias ('C', 'ForegroundColor', 'FGC')] [ConsoleColor[]]$Color = [ConsoleColor]::White,
        [alias ('B', 'BGC')] [ConsoleColor[]]$BackGroundColor = $null,
        [alias ('Indent')][int] $StartTab = 0,
        [int] $LinesBefore = 0,
        [int] $LinesAfter = 0,
        [int] $StartSpaces = 0,
        [alias ('L')] [string] $LogFile = '',
        [Alias('DateFormat', 'TimeFormat')][string] $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss',
        [alias ('LogTimeStamp')][bool] $LogTime = $true,
        [int] $LogRetry = 2,
        [ValidateSet('unknown', 'string', 'unicode', 'bigendianunicode', 'utf8', 'utf7', 'utf32', 'ascii', 'default', 'oem')][string]$Encoding = 'Unicode',
        [switch] $ShowTime,
        [switch] $NoNewLine
    )
    $DefaultColor = $Color[0]
    if ($null -ne $BackGroundColor -and $BackGroundColor.Count -ne $Color.Count) {
        Write-Error "Colors, BackGroundColors parameters count doesn't match. Terminated."
        return
    }
    #if ($Text.Count -eq 0) { return }
    if ($LinesBefore -ne 0) { for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host -Object "`n" -NoNewline } } # Add empty line before
    if ($StartTab -ne 0) { for ($i = 0; $i -lt $StartTab; $i++) { Write-Host -Object "`t" -NoNewline } }  # Add TABS before text
    if ($StartSpaces -ne 0) { for ($i = 0; $i -lt $StartSpaces; $i++) { Write-Host -Object ' ' -NoNewline } }  # Add SPACES before text
    if ($ShowTime) { Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline } # Add Time before output
    if ($Text.Count -ne 0) {
        if ($Color.Count -ge $Text.Count) {
            # the real deal coloring
            if ($null -eq $BackGroundColor) {
                for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
            } else {
                for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
            }
        } else {
            if ($null -eq $BackGroundColor) {
                for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
                for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -NoNewline }
            } else {
                for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
                for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -BackgroundColor $BackGroundColor[0] -NoNewline }
            }
        }
    }
    if ($NoNewLine -eq $true) { Write-Host -NoNewline } else { Write-Host } # Support for no new line
    if ($LinesAfter -ne 0) { for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host -Object "`n" -NoNewline } }  # Add empty line after
    if ($Text.Count -and $LogFile) {
        # Save to file
        $TextToFile = ""
        for ($i = 0; $i -lt $Text.Length; $i++) {
            $TextToFile += $Text[$i]
        }
        $Saved = $false
        $Retry = 0
        Do {
            $Retry++
            try {
                if ($LogTime) {
                    "[$([datetime]::Now.ToString($DateTimeFormat))] $TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append -ErrorAction Stop -WhatIf:$false
                } else {
                    "$TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append -ErrorAction Stop -WhatIf:$false
                }

                $Saved = $tr

                $Saved = $true
            } catch {
                if ($Saved -eq $false -and $Retry -eq $LogRetry) {
                    $PSCmdlet.WriteError($_)
                } else {
                    Write-Warning "Write-Color - Couldn't write to log file $($_.Exception.Message). Retrying... ($Retry/$LogRetry)"
                }
            }
        } Until ($Saved -eq $true -or $Retry -ge $LogRetry)
    }
}

