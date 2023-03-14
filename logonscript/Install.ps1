#region Config
$client = "BBZ"
$scriptsPath = "$env:ProgramData\$client\Scripts\LogonScript"
$logPath = "$env:ProgramData\$client\Logs"
$logFile = "$logPath\LogonScript-RunOnceConfig.log"
$psRun = "psRun.vbs"
$logonScript = "LangugageSwitchLogon.ps1"
$ScheduledTask = "BBZ_Logonscript.xml"
$buildId = "98ad7d19-0834-4d8d-b2e6-976011fda6c5"
#endregion
#region Logging
if (!(Test-Path $scriptsPath)) {
    New-Item -Path $scriptsPath -Type Directory -Force | Out-Null
}
if (!(Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}

if (Test-Path "$scriptsPath\$logonScript") {
    Remove-Item -Path "$scriptsPath\$logonScript" -Force
}
Start-Transcript -Path "$logFile" -Force
#endregion
#region Logon Script Contents
Write-Host "Creating logon script and storing: $scriptsPath\$logonScript" -ForegroundColor Yellow
Expand-Archive "$($PSScriptRoot)\Files.zip" -Destination "$scriptsPath" -Force
#Copy-Item "$PSScriptRoot\$logonScript" -Destination "$scriptsPath\$logonScript" -Force
#endregion

#region Scheduled Task
try {

    Register-ScheduledTask -xml (Get-Content "$scriptsPath\$ScheduledTask" | Out-String) -TaskName "BBZ_Logonscript" -Force

}
catch {
    $errMsg = $_.Exception.Message
}
finally {
    if ($errMsg) {
        Write-Warning $errMsg
        Stop-Transcript
        throw $errMsg
    }
    else {
        Write-Host "script completed successfully.."
        "done." | Out-File "$env:temp\$buildId`.txt" -Encoding ASCII -force
        Stop-Transcript
    }
}
#endregion