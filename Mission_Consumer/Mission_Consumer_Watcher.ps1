
$folder = 'D:\Arma3\missions\iceberg_sideop\Automation'
$filter = '*.zip'
$fsw = New-Object IO.FileSystemWatcher $folder, $filter -Property @{ IncludeSubdirectories = $true}
$fsw.EnableRaisingEvents = $true

$onCreated = Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action {
    try {
    $path = $Event.SourceEventArgs.FullPath
    # A file has been added, run your ps commands here. e. g.
    Start-Sleep -Seconds 5
    D:\Arma3\scripts\Randys_Test_Bucket\Mission_Consumer_V1.ps1
    Write-Host "We did it"
    }
    catch {
    Write-Host "Resetting"
    }
}



# Get-EventSubscriber -SourceIdentifier FileCreated

# Unregister-Event -SourceIdentifier FileCreated