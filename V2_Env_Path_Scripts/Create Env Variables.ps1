    [System.Environment]::SetEnvironmentVariable('ARMAPATH', "D:\Arma3\", [System.EnvironmentVariableTarget]::Machine) #setting the machine's environment variable that all scripts will use
    [System.Environment]::SetEnvironmentVariable('ARMAPATH', "D:\Arma3\", [System.EnvironmentVariableTarget]::Process) #setting the current process' environment variable that scripts will use

    [System.Environment]::SetEnvironmentVariable('STEAMCMDPATH', "D:\SteamCMD.GUI\", [System.EnvironmentVariableTarget]::Machine) #setting the machine's environment variable that all scripts will use
    [System.Environment]::SetEnvironmentVariable('STEAMCMDPATH', "D:\SteamCMD.GUI\", [System.EnvironmentVariableTarget]::Process) #setting the current process' environment variable that scripts will use
