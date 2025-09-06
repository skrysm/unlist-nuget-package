#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$True)]
    [string]
    $PackageId
)

# Stop on every error
$script:ErrorActionPreference = 'Stop'

try {
    ########################################################################

    if (-Not $env:NUGET_API_KEY) {
        Write-Error 'You need to specify your NuGet API key via "$env:NUGET_API_KEY".'
    }

    Write-Host "Determine versions to unlist..."

    # IMPORTANT: The package id must all be lower-case or else it won't work.
    #   See: https://github.com/NuGet/NuGetGallery/issues/9600
    $versions = (Invoke-RestMethod "https://api.nuget.org/v3-flatcontainer/$($PackageId.ToLowerInvariant())/index.json").versions

    Write-Host "Found $($versions.Count) versions to unlist."
    Write-Host

    foreach ($version in $versions) {
        Write-Host
        Write-Host -ForegroundColor Cyan "Unlisting version $version..."

        dotnet nuget delete $PackageId $version --api-key $env:NUGET_API_KEY --source nuget.org --non-interactive

        if (-Not $?) {
            Write-Error "dotnet nuget delete' failed."
        }
    }

    ########################################################################
}
catch {
    function LogError([string] $exception) {
        Write-Host -ForegroundColor Red $exception
    }

    # Type of $_: System.Management.Automation.ErrorRecord

    # NOTE: According to https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/windows-powershell-error-records
    #   we should always use '$_.ErrorDetails.Message' instead of '$_.Exception.Message' for displaying the message.
    #   In fact, there are cases where '$_.ErrorDetails.Message' actually contains more/better information than '$_.Exception.Message'.
    if ($_.ErrorDetails -And $_.ErrorDetails.Message) {
        $unhandledExceptionMessage = $_.ErrorDetails.Message
    }
    elseif ($_.Exception -And $_.Exception.Message) {
        $unhandledExceptionMessage = $_.Exception.Message
    }
    else {
        $unhandledExceptionMessage = 'Could not determine error message from ErrorRecord'
    }

    # IMPORTANT: We compare type names(!) here - not actual types. This is important because - for example -
    #   the type 'Microsoft.PowerShell.Commands.WriteErrorException' is not always available (most likely
    #   when Write-Error has never been called).
    if ($_.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.WriteErrorException') {
        # Print error messages (without stacktrace)
        LogError $unhandledExceptionMessage
    }
    else {
        # Print proper exception message (including stack trace)
        # NOTE: We can't create a catch block for "RuntimeException" as every exception
        #   seems to be interpreted as RuntimeException.
        if ($_.Exception.GetType().FullName -eq 'System.Management.Automation.RuntimeException') {
            LogError "$unhandledExceptionMessage$([Environment]::NewLine)$($_.ScriptStackTrace)"
        }
        else {
            LogError "$($_.Exception.GetType().Name): $unhandledExceptionMessage$([Environment]::NewLine)$($_.ScriptStackTrace)"
        }
    }

    exit 1
}
