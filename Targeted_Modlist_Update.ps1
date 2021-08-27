Start-Transcript -path D:\Arma3\configs\iceberg_sideop\log.txt -append

$modlist = Get-ChildItem D:\Arma3\configs\iceberg_sideop\modlist*.txt | Out-GridView -Title 'Choose your modlist' -PassThru | ForEach-Object { $_.FullName }
$modnumber = (Get-Content $modlist)|ForEach { $_.Split("=")[-1] }
ForEach ($modnum in $modnumber) {
    D:\SteamCMD.GUI\steamcmd.exe +login Iceberg_Gaming_Team +workshop_download_item 107410 $modnum +validate +quit
    }

    
Stop-Transcript