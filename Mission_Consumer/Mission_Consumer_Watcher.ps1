<#
https://stackoverflow.com/questions/37477187/run-ps-commands-every-time-a-file-is-added-to-a-folder

 Get-EventSubscriber -SourceIdentifier FileCreated

 Unregister-Event -SourceIdentifier FileCreated

#>

#setting shell to Admin

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
$host.ui.RawUI.WindowTitle = "Mission Consumer”


$folder = 'D:\Arma3\missions\iceberg_sideops\Automation'
$filter = '*.zip'
$fsw = New-Object IO.FileSystemWatcher $folder, $filter -Property @{ IncludeSubdirectories = $true}
$fsw.EnableRaisingEvents = $true

Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action {
    try {
    $path = $Event.SourceEventArgs.FullPath
    # A file has been added, run your ps commands here. e. g.
    Start-Sleep -Seconds 5
    D:\Arma3\scripts\Arma3PSTools\Mission_Consumer\Mission_Consumer_V1.3.1.ps1
    Write-Host "Package Consumed at $(Get-Date)"
    }
    catch {
    Write-Host "Error encountered, Watcher Reset"
    }
}