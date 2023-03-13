#region Config
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$client = "BBZ"
$logPath = "$ENV:ProgramData\$client\Logs"
$logFile = "$logPath\LogonScript.log"
$user = whoami /upn
$errorOccurred = $null
$fileServer = 'fileserver.corp'
$funcUri = 'https://{putURIhere}'
#endregion
#region Functions
function Set-Language {
    <#
    .SYNOPSIS
        Switch Language
    .PARAMETER language
        The language to be set

    .EXAMPLE
        Set-Language -language "de-DE"
    #>
    [cmdletbinding(SupportsShouldProcess = $True)]
    param (
        [string]$language
    )
    $ActualLanguage = Get-WinUILanguageOverride | Select-Object -ExpandProperty Name
    if ($language -ne $ActualLanguage){
        Set-WinUILanguageOverride -Language $language
        Set-WinUserLanguageList $language -Force
        Set-Culture -CultureInfo $language
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\LanguageComponentsInstaller\" -TaskName "ReconcileLanguageResources" | Start-ScheduledTask
        (Get-WmiObject -Class Win32_OperatingSystem).Win32Shutdown(0)

    }
    else {
        Write-Host "Actual language $($ActualLanguage) matches the users preferredLanguag $($language)" -ForegroundColor Red
        }
}

#endregion
#region logging
if (!(Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force
}
Start-Transcript -Path $logFile -Force
#endregion
#region Logon script
try {
    Write-Host "Hello $user.." -ForegroundColor Green
    Write-Host "Just going to set your preferredLanguage on this computer" -ForegroundColor Green
    #endregion
    #region Get group memberships
    $fParams = @{
        Method      = 'Get'
        Uri         = "$funcUri&user=$user"
        ContentType = 'Application/Json'
    }
    $grpMembership = Invoke-RestMethod @fParams
    #endregion
    #region Map drives
    if ($grpMembership.languages) {
        $grpMembership.languages | Format-Table
        foreach ($lang in $grpMembership.languages) {
            if ($lang -ne $null) {
                Write-Host "Setting $($lang.language)"
                Set-Language -language $lang.language 
            }
        }
    }
    #endregion
}
catch {
    $errorOccurred = $_.Exception.Message
}
finally {
    if ($errorOccurred) {
        Write-Warning "Logon Script completed with errors."
        Stop-Transcript
        Throw $errorOccurred
    }
    else {
        Write-Host "Logon Script completed successfully."
        Stop-Transcript
    }
}
#endregion