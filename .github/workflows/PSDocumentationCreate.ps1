Install-Module platyps -Force
Import-Module platyps

$PowershellFiles = Get-ChildItem *.ps1 -Recurse

foreach ($PowershellFile in $PowershellFiles) {
    Set-Location $PowershellFile.Directory.FullName

    New-MarkdownHelp -Command ".\$($PowershellFile.Name)" -OutputFolder .\ -NoMetadata -Force -ErrorAction SilentlyContinue | Move-Item -Destination README.md -Force
}