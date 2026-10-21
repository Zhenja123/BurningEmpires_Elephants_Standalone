$ErrorActionPreference = "Stop"

$GameBin = "C:\Program Files (x86)\Steam\steamapps\common\Mount & Blade II Bannerlord\bin\Win64_Shipping_Client"
$Project = Join-Path $PSScriptRoot "BE_Elephants_Standalone_Runtime.csproj"

Write-Host "Bannerlord elephant standalone runtime - build check" -ForegroundColor Cyan
Write-Host "Game assembly folder: $GameBin"

if (!(Test-Path $GameBin)) {
    throw "Game assembly folder not found. Edit `$GameBin in build.ps1 to match your installation."
}

$required = @(
    "TaleWorlds.MountAndBlade.dll",
    "TaleWorlds.Core.dll",
    "TaleWorlds.Library.dll",
    "TaleWorlds.Engine.dll",
    "TaleWorlds.DotNet.dll",
    "TaleWorlds.InputSystem.dll",
    "TaleWorlds.ObjectSystem.dll"
)

foreach ($name in $required) {
    $path = Join-Path $GameBin $name
    if (!(Test-Path $path)) {
        throw "Required assembly not found: $path"
    }
    Write-Host "Found $name"
}

$env:GameBin = $GameBin
Write-Host ""
Write-Host "Starting build. First build may need internet access to restore .NET Framework reference assemblies."
dotnet build $Project -p:GameBin="$GameBin" --verbosity minimal
if ($LASTEXITCODE -ne 0) {
    throw "Build failed. Copy the complete error output and send it back."
}
Write-Host ""
Write-Host "Build succeeded. This is only a scaffold; in-game behavior still requires porting and testing." -ForegroundColor Green
