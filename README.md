# Unlist NuGet Packages

This repo contains a PowerShell script - `Unlist-NuGetPackages.ps1` - to unlist all versions of a NuGet package.

To use it, first **create a [NuGet API key](https://www.nuget.org/account/apikeys)** with **Unlist or relist package versions** scope.

Next open a PowerShell session and specify the API key like this:

```pwsh
$env:NUGET_API_KEY = '<your-api-key>'
```

Then call:

```
./Unlist-NuGetPackage.ps1 '<your-package-id>'
```
