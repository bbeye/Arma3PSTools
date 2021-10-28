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


#>

import-module Update-Arma3Mod


function Get-Arma3ModlistFormat {
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
        [switch]$Quiet
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

            if ($NoUpdate){
            }
            elseif ($Quiet) {
                Update-Arma3Mod -modNumber $modnumber | Out-Null
            } else {
                Update-Arma3Mod -modNumber $modnumber
                }


            <# DEPRECATED
            Write-Color "LOADING ", "$modname $modnumber FAILED:", " Check $RepoPath for mod" -Color White,Red,Yellow
            $ModlistError = 1
            $MissingMods += "`n$modname = $modnumber"
            ### Insert query to download single mod if needed
            #>
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