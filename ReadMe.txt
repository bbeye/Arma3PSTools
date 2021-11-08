Move Arma3Modules.psm1 to C:\Program Files\WindowsPowerShell\Modules\Arma3Modules\Arma3Modules.psm1

Dev script to Import-Module:
Import-Module -name 'C:\Program Files\WindowsPowerShell\Modules\Arma3Modules\Arma3Modules.psm1'

Commands for symbolic links for modlists:

mklink "D:\Arma3\configs\17th_operations\modlist.txt" "D:\Arma3\scripts\!Modfiles\17th_modlist.txt"
mklink "D:\Arma3\configs\17th_training\modlist.txt" "D:\Arma3\scripts\!Modfiles\17th_modlist.txt"
mklink "D:\Arma3\missions\iceberg_sideop\Automation\Modlists\17thBN_base_modlist.txt" "D:\Arma3\scripts\!Modfiles\17th_modlist.txt"
mklink "D:\Arma3\configs\iceberg_persistent\modlist.txt" "D:\Arma3\scripts\!Modfiles\iceberg_modlist.txt"
mklink "D:\Arma3\missions\iceberg_sideop\Automation\Modlists\iceberg_base_modlist.txt" "D:\Arma3\scripts\!Modfiles\iceberg_modlist.txt"

Commands for environmental variables:

[System.Environment]::SetEnvironmentVariable('ARMAPATH', "D:\Arma3\", [System.EnvironmentVariableTarget]::Machine) #setting the machine's environment variable that all scripts will use
[System.Environment]::SetEnvironmentVariable('ARMAPATH', "D:\Arma3\", [System.EnvironmentVariableTarget]::Process) #setting the current process' environment variable that scripts will use

[System.Environment]::SetEnvironmentVariable('STEAMCMDPATH', "D:\SteamCMD.GUI\", [System.EnvironmentVariableTarget]::Machine) #setting the machine's environment variable that all scripts will use
[System.Environment]::SetEnvironmentVariable('STEAMCMDPATH', "D:\SteamCMD.GUI\", [System.EnvironmentVariableTarget]::Process) #setting the current process' environment variable that scripts will use
