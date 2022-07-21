$file = "$($env:ARMAPATH)configs\17th_training\17th_training_server.cfg"

$newestTrainingMap = Get-ChildItem D:\arma3\missions\17th_training | sort LastWriteTime | select -last 1
$newestTrainingMap.basename

Stop-Arma3Server -launchID 17th_training

#template = "17TH_BN_Training_Facility_V1_3.isladuala3";

$regex = 'template = ".*"'
$replace = "template = `"$($newestTrainingMap.BaseName)`""

(Get-Content $file) -replace $regex, $replace | Set-Content $file

Start-Arma3Server -launchID 17th_training -Port 2402 -modlistSelect Automatic -runType Server
