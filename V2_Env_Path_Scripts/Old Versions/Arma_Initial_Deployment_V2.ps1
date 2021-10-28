<#
V2 sets an environmental path to the listed directory. All scripts following this version will use this path going forward.
#>


#setting shell to Admin

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

<# WHERE ARE WE INSTALLING THINGS?#>

    if (Test-Path $env:ArmaPath)
        {
        $confirmArmaPathBit = Read-Host "It looks like your current Arma directory is $env:ArmaPath. Is this correct? (Y/N)"
        }
            if ($confirmArmaPathBit -eq "Y")
            {
            $armaDir=$env:ArmaPath
            
            }
 while ((Test-Path $env:ArmaPath) -eq $false) {

    if ((Test-Path $armaDir -errorAction SilentlyContinue) -eq $false) 
        {
        Write-Output "`n$armaDir is an invalid directory, please create the requested directory and try again`n"
        }

    $armaDir = Read-Host -Prompt "Please enter the directory you want everything located in. Example: C:\Arma3\"

    [System.Environment]::SetEnvironmentVariable('ARMAPATH', "$armaDir", [System.EnvironmentVariableTarget]::Machine) #setting the machine's environment variable that all scripts will use
    [System.Environment]::SetEnvironmentVariable('ARMAPATH', "$armaDir", [System.EnvironmentVariableTarget]::Process) #setting the current process' environment variable that scripts will use

    }

Write-Output "`nEverything Arma will go in $env:ArmaPath"

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


<# CREATING THE REQUIRED DIRECTORIES #>
$armaDir = "$env:ArmaPath"
$baseDirs = @("Configs", "Profiles", "Scripts", "Missions", "Servers")

foreach ($dir in $baseDirs) {
if (Test-Path "$($armaDir)$($dir)") {
    Write-Output "$($armaDir)$($dir) already exists"
    } else 
    {
    mkdir "$($armaDir)$($dir)"
    }
if (Test-Path "$($armaDir)$($dir)\$serverName") {
    Write-Output "$($armaDir)$($dir) already exists"
    } else 
    {
    mkdir "$($armaDir)$($dir)\$serverName"
    }    
}


<# LOGIN TO STEAM, IT SHOULD CACHE THESE CREDS #>
$steamLogin = Read-Host -prompt "Enter the steam login to sign in"

C:\steamcmd\steamcmd.exe +login $steamLogin +quit

<# Building the initial modlist from the ShadowMod#>
Import-Module $env:ArmaPath\Scripts\Arma3PSTools\Build_Modlist_Module_V2.psm1

$shadowModName = Read-Host "Shadowmod Name? Example: 17th_BN_Shadow_Mod"
$shadowModNumber = Read-Host "Shadowmod number? Example: 2414840966"

Build-Modlist -shadowModName "$($LaunchID)_Shadow_Mod" -shadowModNumber "$shadowModNumber" |Out-File "$($armaDir)configs\$serverName\modlist.txt"


<# Pulling the config files #>

Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CFG (*.cfg)| *.cfg"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog
}

Clear-Host

pwd 

$configBit = Read-Host "`Do you want to: `n 1. Use your own config file? `n 2: Use the default file? `n`n Enter the number of your choice (1|2)"

switch ($configBit) 
    {
    1   {
        Clear-host
        Write-Output "`nSelect the basic config."
        $basicConfig = Get-FileName("$($env:ArmaPath)Configs\$serverName\") | 
        Copy-Item $basicConfig -destination "$($env:ArmaPath)Configs\$serverName\$($serverName)_Basic.cfg"

        Clear-host
        Write-Output "`nSelect the server config."
        $serverConfig = Get-FileName("$($env:ArmaPath)Configs\$serverName\") 
        Copy-Item $serverConfig.FileName  -destination "$($env:ArmaPath)Configs\$serverName\$($serverName)_server.cfg"

        Clear-Host
        Write-Output "`nOpening server config for initial setup."
        notepad.exe "$($env:ArmaPath)Configs\$serverName\$($serverName)_server.cfg"
        }

    2   {
        Write-Output "`nGenerating default configs at $($env:ArmaPath)Configs\$serverName"

        Copy-Item -path ".\Default_Configs\Default_basic.cfg" -destination "$($env:ArmaPath)Configs\$serverName\$($serverName)_Basic.cfg"
        Copy-Item -path ".\Default_Configs\Default_server.cfg" -destination "$($env:ArmaPath)Configs\$serverName\$($serverName)_server.cfg"

        if (Test-Path "$($env:ArmaPath)Configs\$serverName\$($serverName)_Basic.cfg")
            {
            Write-Output "`nLooks like Config deployment failed. Deploy manually."
            }
            else
            {
            Write-Output "`nOpening server config for initial setup."
            notepad.exe "$($env:ArmaPath)Configs\$serverName\$($serverName)_Basic.cfg"
            }
        }
    }

<# Final confirmation #>

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

Pause



