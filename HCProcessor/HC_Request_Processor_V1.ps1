﻿<#
https://stackoverflow.com/questions/37477187/run-ps-commands-every-time-a-file-is-added-to-a-folder

 Get-EventSubscriber -SourceIdentifier FileCreated

 Unregister-Event -SourceIdentifier FileCreated

#>

#setting shell to Admin

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
$host.ui.RawUI.WindowTitle = "HC Request Processor"


$folder = 'D:\Arma3\missions\HC Requests\Automation'
$filter = '*.json'
$fsw = New-Object IO.FileSystemWatcher $folder, $filter -Property @{ IncludeSubdirectories = $true}
$fsw.EnableRaisingEvents = $true

Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action {
    try {
    $path = $Event.SourceEventArgs.FullPath
    # A file has been added, run your ps commands here. e. g.
    Start-Sleep -Seconds 5
    D:\Arma3\scripts\Arma3PSTools\HCProcessor\Headless_Client_Processor_V1.0.ps1
    Write-Host "HC Request Consumed at $(Get-Date)"
    }
    catch {
    Write-Host "Error encountered, Watcher Reset"
    }
}