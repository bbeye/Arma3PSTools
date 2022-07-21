<#
https://stackoverflow.com/questions/37477187/run-ps-commands-every-time-a-file-is-added-to-a-folder

 Get-EventSubscriber -SourceIdentifier FileCreated

 Unregister-Event -SourceIdentifier FileCreated

#>


$folder = 'D:\Arma3\missions\17th_Training'
$filter = '*.pbo'
$fsw = New-Object IO.FileSystemWatcher $folder, $filter -Property @{ IncludeSubdirectories = $true}
$fsw.EnableRaisingEvents = $true

$onCreated = Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action {
    try {
    $path = $Event.SourceEventArgs.FullPath
    # A file has been added, run your ps commands here. e. g.
    Start-Sleep -Seconds 5
    D:\Arma3\scripts\Arma3PSTools\V1_Training_Server_Update\Update_Training_Map.ps1
    Write-Host "Package Consumed at $(Get-Date)"
    }
    catch {
    Write-Host "Error encountered, Watcher Reset"
    }
}



