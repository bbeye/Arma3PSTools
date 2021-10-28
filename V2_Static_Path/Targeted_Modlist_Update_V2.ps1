##Version 0.2##

Start-Transcript -path D:\Arma3\configs\iceberg_sideop\log.txt -append

$modfile = Get-ChildItem D:\Arma3\configs\iceberg_sideop\modlist*.txt | Out-GridView -Title 'Choose your modlist' -PassThru | ForEach-Object { $_.FullName }
$modlist = Get-Content $modfile

ForEach ($mod in $modlist) {
    $modnumber = $mod.Split("=")[-1]
    $modname = $mod.Split("=")[0]
    echo "DOWNLOADING $modname"
    D:\SteamCMD.GUI\steamcmd.exe +login Iceberg_Gaming_Team +workshop_download_item 107410 $modnumber validate +quit
    }

    
Stop-Transcript