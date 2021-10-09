
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

<# WHERE ARE WE INSTALLING THINGS?#>

DO {
    if ((Test-Path $armaDir -errorAction SilentlyContinue) -eq $false) 
        {
        Write-Output "`n$armaDir is an invalid directory, please create the requested directory and try again`n"
        } elseif (Test-Path $env:ArmaPath)
        {
        $confirmArmaPathBit = Read-Host "It looks like your current Arma directory is $env:ArmaPath. Is this correct? (Y/N)"
        }
            if ($confirmArmaPathBit -eq "Y")
            {
            break
            }

    $armaDir = Read-Host -Prompt "Please enter the directory you want everything located in. Example: C:\Arma3\"
    [System.Environment]::SetEnvironmentVariable('ARMAPATH', "$armaDir", [System.EnvironmentVariableTarget]::Machine) #setting the machine's environment variable that all scripts will use
    [System.Environment]::SetEnvironmentVariable('ARMAPATH', "$armaDir", [System.EnvironmentVariableTarget]::Process) #setting the current process' environment variable that scripts will use

    } while ((Test-Path $env:ArmaPath) -eq $false)

Write-Output "`nEverything Arma will go in $env:ArmaPath"



<# CREATING THE REQUIRED DIRECTORIES #>
$armaDir = "C:\Arma3\"
$baseDirs = @("Configs", "Profiles", "Scripts", "Missions", "Servers")

foreach ($dir in $baseDirs) {
if (Test-Path "$($armaDir)$($dir)") {
    Write-Output "$($armaDir)$($dir) already exists"
    } else 
    {
    mkdir "$($armaDir)$($dir)"
    }
}


<# NAMING THE PRIMARY SERVER #>


DO {


    $serverName = Read-Host -Prompt "Please enter the name of the server, do not use a directory. NO SPACES. Example: Liberation"
    
    $armaInstallPath = "$($armaDir)Servers\$($serverName)"

    #Verifying the path does not already exist
    #Also verifying no spaces in the name. I'm sure it'd be fine, by why test it. NO SPACES

    while ((Test-Path $armaInstallPath) -or ($serverName -match "\s")) 
    {
        Write-Output "`n$armaInstallPath already exists or it has a space in it, please select a new name and try again`n"
        $serverName = Read-Host -Prompt "Please enter the name of the server, do not use a directory. NO SPACES. Example: Liberation"
        $armaInstallPath = "$($armaDir)Servers\$($serverName)"
    }
    
    write-output "`nThe new server will exist in: $armaInstallPath"

    $confirmSNBit = Read-Host "`nAre you sure you want the server name to be $($serverName)? (Y/N)"
        if ($confirmSNBit -eq "Y")
        {
        break
        }

    } while ($confirmSNBit -ne "Y")



<# LOGIN TO STEAM, IT SHOULD CACHE THESE CREDS #>
$steamLogin = Read-Host -prompt "Enter the steam login to sign in"

C:\steamcmd\steamcmd.exe +login $steamLogin +quit

Clear-host

Write-Output "`nOK. We are going to install an Arma 3 Dedicated server at $armaInstallPath using the account $($steamLogin)."

    $confirmInstallBit = Read-Host "`nDo you really want to do this, and potentially play more Arma? Anything other than Y will end this script. (Y/N)"
        if ($confirmInstallBit -ne "Y")
        {
        exit
        }

<# INSTALLING THE PRIMARY SERVER #>

C:\steamcmd\steamcmd.exe +login $steamLogin +force_install_dir $armaInstallPath +app_update 233780 +validate +quit

Write-Output "`nYour new Arma Server has been deployed. I hope you know what you've done."