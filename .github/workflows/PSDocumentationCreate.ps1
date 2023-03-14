$InformationPreference = 'Continue'

Install-Module platyps -Force
Import-Module platyps

$PowershellFiles = Get-ChildItem *.ps1 -Recurse

foreach ($PowershellFile in $PowershellFiles) {
    Set-Location $PowershellFile.Directory.FullName

    New-MarkdownHelp -Command ".\$($PowershellFile.Name)" -OutputFolder .\ -NoMetadata -Force -ErrorAction SilentlyContinue | Out-Null

    if (Test-Path "$($PowershellFile.Name).md") {
        Write-Information "Successfully created documentation for $($PowershellFile.Name)"
        Move-Item -Destination README.md -Path "$($PowershellFile.Name).md" -Force
    }
    else {
        Write-Warning "Unable to create documentation for $($PowershellFile.Name)"
    }
}