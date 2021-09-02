﻿#$shadowModName="17th Ranger Battalion Shadow Mod"
#$shadowModNumber=2414840966


function Get-Modlist {
    Param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $shadowModName,

        [Parameter(Mandatory=$true)]
        [string[]]
        $shadowModNumber
    )

$modlist = wget https://steamcommunity.com/sharedfiles/filedetails/?id=$shadowModNumber
$modlist.Content | out-file .\modlist.txt

if ((Get-Content .\modlist.txt) -join "`n" -match '<div class="requiredItemsContainer" id="RequiredItems">([\s\S]*)<!-- created by -->') { $matches[1] }

$pulledOutput = if ((Get-Content .\modlist.txt) -join "`n" -match '<div class="requiredItemsContainer" id="RequiredItems">([\s\S]*)<!-- created by -->') { $matches[1] }

$pulledOutput | Out-File .\modlistextract.txt

Write-Host $shadowModName"="$shadowModNumber

$num=0
$runbit=0
foreach ($line in (gc .\modlistextract.txt)) {
    #grab the link

    If ($runBit -ne 2) 
    {     
        if ($line -like '*https*') 
        {
        $modNumber = $line -replace '\D+(\d+)\D+','$1'
        $runBit += 1
        #Write-Host $runbit modNumber
        }

        if ($line -notlike '*</a*' -and $line -notlike '*<a*' -and $line -notlike '*<div class="requiredItem">*' -and $line -notlike $null)
        {
        $modName = $line -replace '\t+|</div>'
        $runBit += 1
        #Write-Host $runbit modName
        }
    } elseif ($runbit -eq 2 -and $modName -ne '')
    {
    
    Write-Host $modName"="$modNumber
    $runbit = 0
    }
}
}