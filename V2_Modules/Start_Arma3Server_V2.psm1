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
$LaunchID="jtfa_ops"
$Port="2302"
$modlist="Automatic"


        [ValidatePattern("\AAutomatic\z|\ADateAware\z|\ASpecificModlist\z")]
#>


function Start-Arma3Server {
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


$Date = (Get-Date -Format yyyyMMdd)
$RepoPath=           "C:\SteamCMD\steamapps\workshop\content\107410\"           #Mods location
$serverExeName=      "arma3server.exe"                                         #64-bit version would be arma3server_x64.exe
$ArmaPath=           "$($env:ARMAPATH)servers\$LaunchID"                                   #Executable location
$serverConfigPath=   "$($env:ARMAPATH)configs\$LaunchID\$($LaunchID)_server.cfg"   #Server Config File Path
$basicConfigPath=    "$($env:ARMAPATH)configs\$LaunchID\$($LaunchID)_basic.cfg"     #Basic Config File Path
$ProfilesPath=       "$($env:ARMAPATH)profiles\$LaunchID"                              #Profiles/Logs location


# Server Mods
$ServerMods="@asm;@AdvancedTowing;@AdvancedSlingloading;@DisableBI;@R3"
$HeadlessMods="@asm"

<#
#
#
#TEST VARIABLES#
$LaunchID="Test2"
$port=2302 #,2402,2602,2702
$modlist="Automatic" #$args[2] #'Automatic','DateAware','SpecificModlist'
$runtype="Client"
#
#
#>


#Verifying no other sessions exist
    $PriorityFilter="%$LaunchID\\arma3server.exe"
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


#Building the modlist

if ($runType -eq "Client") {
    $ArmaMods = Get-Arma3ModlistFormat -ServerModNames $HeadlessMods -modlistSelect $modlistSelect -LaunchID $LaunchID -Quiet -NoUpdate -ErrorAction Stop
	

} elseif ($runType -eq "Server"){
    $ArmaMods = Get-Arma3ModlistFormat -ServerModNames $ServerMods -modlistSelect $modlistSelect -LaunchID $LaunchID -Quiet -NoUpdate -ErrorAction Stop
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


Start-Process  .\arma3server.exe -ArgumentList $argumentlist -WindowStyle Minimized

#Setting priority of Executables to High
    
    $PriorityFilter="%$LaunchID\\arma3server.exe"
    Get-WmiObject win32_process -filter "ExecutablePath LIKE `"$PriorityFilter`""| ForEach-Object { $_.SetPriority(128) }


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


#start /min "iceberg_sideop" /realtime /affinity FF "D:\\arma3\\servers\\iceberg_sideop\\arma3server.exe" -port=2702 -profiles=$($env:ARMAPATH)profiles\iceberg_sideop\ -name=HC%i "-mod=@asm;"

#>





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

}