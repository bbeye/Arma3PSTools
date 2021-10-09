<#
This module will use the provided mod number to gather the mod's last updated date.
Should the mod be unlisted, the web page will be scraped. Should anything change on Steam's side, this module will need to be updated to reflect.

Required input:

-ModNumber = The modnumber from the steam page.

Recommended to use in tandem with Get-Arma3ShadowMod

#>


#$modnumber = 2414840966



function Get-Arma3LastUpdated {
    Param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $modNumber
    )
    

    $modsLocation = "C:\steamcmd\steamapps\workshop\content\107410\"
    $steamCMD = "C:\steamcmd"
    $timeUpdatedLocally = (get-childitem $modsLocation | where Name -EQ $ModNumber).LastWriteTime

    $xml = Invoke-RestMethod -uri 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/' -Method Post -Body "itemcount=1&publishedfileids[0]=$ModNumber"
     
    if ($xml.response.publishedfiledetails.time_updated -eq $null) {

        $modlistRaw = wget "https://steamcommunity.com/sharedfiles/filedetails/?id=$modNumber"

        $pulledOutput = ($modlistRaw.Content | select-string -pattern '<div class="detailsStatRight">(?<date>\D.*)@.(?<time>\d.*)<\/div>' -AllMatches).Matches[1]

        $timeUpdatedSteamUnparsed = $pulledOutput.Groups[1].Value + $pulledOutput.Groups[2].Value
       
        
        $timeUpdatedSteam = [datetime]::parseexact($timeUpdatedSteamUnparsed, 'MMM d h:mmtt', $null)

    } else {
    
    $timeUpdatedSteam = (Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($xml.response.publishedfiledetails.time_updated))

    }

     CD $steamCMD #setting directory for steamCMD calls

    #Checking if mod exists at all
    if ($timeUpdatedLocally -eq $null) {
     Write-Output "$modNumber does not exist, downloading"
     .\steamcmd.exe +login 100dollarrandy +workshop_download_item 107410 $modnumber validate +quit

    } #Checking for the last updated date was today or day before 
    elseif ($timeUpdatedSteam -gt (get-childitem $modsLocation | where Name -EQ $ModNumber).LastWriteTime) {
        Write-Output "$modNumber last updated on $timeUpdatedSteam"
        #Checking if the mod has already been updated today
            Write-Output "Mod updating"
            #mod updated in steam, not updated locally yet, download mods
            CD $steamCMD
            .\steamcmd.exe +login 100dollarrandy +workshop_download_item 107410 $modnumber validate +quit
                
    } 
    else {
    Write-Output "$modNumber last updated on Steam on $timeUpdatedSteam, local update was $timeUpdatedLocally. No Update Needed."
    }
    
}