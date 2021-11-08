##Version 0.2##

Start-Transcript -path D:\Arma3\configs\iceberg_sideop\Automated_Mod_Update_log.txt -append
$modfile=$args[0]
write-host "Downloading mods from $modfile"

#$modfile = "D:\Arma3\configs\iceberg_sideop\modlist_2021_08_08_18_30.txt"


#$modfile = Get-ChildItem D:\Arma3\configs\iceberg_sideop\modlist*.txt | Out-GridView -Title 'Choose your modlist' -PassThru | ForEach-Object { $_.FullName }
$modlist = Get-Content $modfile
Write-Host "Content Got"

ForEach ($mod in $modlist) {
    $modnumber = $mod.Split("=")[-1]
    $modname = $mod.Split("=")[0]
    echo "DOWNLOADING $modname"
    Update-Arma3Mod -modNumber $modnumber
    }

    
Stop-Transcript