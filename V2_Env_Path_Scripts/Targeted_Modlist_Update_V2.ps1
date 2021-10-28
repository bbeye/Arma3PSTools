##Version 0.2##

Start-Transcript -path "$($env:armapath)configs\privateops\log.txt" -append

$steamCMDDir= "C:\SteamCMD"
$steamCMDLogin= "100dollarrandy"

$modfile = Get-ChildItem "$($env:armapath)configs\*\modlist*.txt" | Out-GridView -Title 'Choose your modlist' -PassThru | ForEach-Object { $_.FullName }
$modlist = Get-Content $modfile

Set-location $steamCMDDir

ForEach ($mod in $modlist) {
    $modnumber = $mod.Split("=")[-1]
    $modname = $mod.Split("=")[0]
    echo "DOWNLOADING $modname"
    .\steamcmd.exe +login 100dollarrandy +workshop_download_item 107410 $modnumber validate +quit
    }

    
Stop-Transcript