$ErrorActionPreference = 'Stop'

$SourceModuleName = 'BurningEmpires_Elephants'
$TargetModuleName = 'BurningEmpires_Elephants_Standalone'
$TargetDisplayName = 'Burning Empires - Elephants Standalone'
$InstallerRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RuntimeSource = Join-Path $InstallerRoot 'bin\Win64_Shipping_Client\BE_Elephants_Standalone_Runtime.dll'

function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Fail([string]$Message) { throw $Message }

try {
    Write-Host 'Burning Empires Elephants standalone installer' -ForegroundColor Green
    Write-Host 'The original BurningEmpires_Elephants folder will not be modified.'

    if (-not (Test-Path -LiteralPath $RuntimeSource -PathType Leaf)) {
        Fail "The standalone runtime DLL is missing: $RuntimeSource"
    }

    $possibleRoots = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\common\Mount & Blade II Bannerlord'),
        (Join-Path $env:ProgramFiles 'Steam\steamapps\common\Mount & Blade II Bannerlord')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'Modules')) }

    $gameRoot = $possibleRoots | Select-Object -First 1

    if (-not $gameRoot) {
        Write-Host 'Could not find the default Steam installation automatically.' -ForegroundColor Yellow
        $gameRoot = Read-Host 'Paste your Bannerlord game folder path (the folder containing Modules)'
        $gameRoot = $gameRoot.Trim('" ')
    }

    $modulesPath = Join-Path $gameRoot 'Modules'
    if (-not (Test-Path -LiteralPath $modulesPath -PathType Container)) {
        Fail "The Modules folder was not found under: $gameRoot"
    }

    $source = Join-Path $modulesPath $SourceModuleName
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        Fail "Required source module not found: $source`nInstall Burning Empires Elephants first, then run this installer again."
    }

    $target = Join-Path $modulesPath $TargetModuleName
    if (Test-Path -LiteralPath $target) {
        Write-Host "A standalone folder already exists: $target" -ForegroundColor Yellow
        $answer = Read-Host 'Replace that standalone folder? A backup will be created first (Y/N)'
        if ($answer -notmatch '^(Y|YES)$') {
            Write-Host 'Cancelled. No files were changed.'
            exit 1
        }
    }

    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $stage = Join-Path $modulesPath ($TargetModuleName + '_staging_' + $stamp)
    $backup = Join-Path $modulesPath ($TargetModuleName + '_backup_' + $stamp)

    Write-Step 'Copying the elephant module to a staging folder'
    New-Item -ItemType Directory -Path $stage | Out-Null

    # Copy the source module contents, including its folder structure and asset packages.
    # Skip the source SubModule.xml so the standalone module can use its own metadata.
    Get-ChildItem -LiteralPath $source -Force | Where-Object { $_.Name -ne 'SubModule.xml' -and $_.Name -ne 'bin' } |
        ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $stage -Recurse -Force
        }

    Write-Step 'Applying the Aserai elephant market settings'
    $marketPatch = Join-Path $InstallerRoot 'market-patch\\be_elephant_items.xml'
    if (-not (Test-Path -LiteralPath $marketPatch -PathType Leaf)) {
        Fail "The market XML patch is missing: $marketPatch"
    }
    $marketItemsDir = Join-Path $stage 'ModuleData\\be_elephants_generated\\items'
    New-Item -ItemType Directory -Path $marketItemsDir -Force | Out-Null
    Copy-Item -LiteralPath $marketPatch -Destination (Join-Path $marketItemsDir 'be_elephant_items.xml') -Force
    [xml]$null = Get-Content -LiteralPath (Join-Path $marketItemsDir 'be_elephant_items.xml') -Raw

    Write-Step 'Installing the standalone runtime DLL'
    $runtimeDir = Join-Path $stage 'bin\Win64_Shipping_Client'
    New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
    Copy-Item -LiteralPath $RuntimeSource -Destination (Join-Path $runtimeDir 'BE_Elephants_Standalone_Runtime.dll') -Force

    Write-Step 'Creating standalone module metadata from the original manifest'
    $sourceManifest = Join-Path $source 'SubModule.xml'
    if (-not (Test-Path -LiteralPath $sourceManifest -PathType Leaf)) {
        Fail "The original module manifest was not found: $sourceManifest"
    }

    # Preserve the original module's XML registrations and dependency metadata.
    # Change only the module identity and replace the empty SubModules node with
    # the standalone runtime entry. The original manifest is never edited.
    [xml]$manifest = Get-Content -LiteralPath $sourceManifest -Raw
    $idNode = $manifest.SelectSingleNode('/Module/Id')
    $nameNode = $manifest.SelectSingleNode('/Module/Name')
    if (-not $idNode -or -not $nameNode) {
        Fail 'The source SubModule.xml did not contain the expected Module/Id and Module/Name nodes.'
    }
    $idNode.SetAttribute('value', $TargetModuleName)
    $nameNode.SetAttribute('value', $TargetDisplayName)

    # The source manifest may depend on the main BurningEmpires module.
    # Remove that dependency from the standalone copy, including load-order metadata.
    foreach ($dep in @($manifest.SelectNodes('/Module/DependedModules/DependedModule'))) {
        if ($dep.GetAttribute('Id') -eq 'BurningEmpires') {
            [void]$dep.ParentNode.RemoveChild($dep)
        }
    }
    foreach ($depMeta in @($manifest.SelectNodes('/Module/DependedModuleMetadatas/DependedModuleMetadata'))) {
        if ($depMeta.GetAttribute('id') -eq 'BurningEmpires') {
            [void]$depMeta.ParentNode.RemoveChild($depMeta)
        }
    }

    $subModulesNode = $manifest.SelectSingleNode('/Module/SubModules')
    if (-not $subModulesNode) {
        $subModulesNode = $manifest.CreateElement('SubModules')
        [void]$manifest.DocumentElement.AppendChild($subModulesNode)
    }
    $subModulesNode.RemoveAll()

    $subModuleNode = $manifest.CreateElement('SubModule')
    $nodeName = $manifest.CreateElement('Name')
    $nodeName.SetAttribute('value', 'Burning Empires Elephants Standalone Runtime')
    [void]$subModuleNode.AppendChild($nodeName)

    $dllName = $manifest.CreateElement('DLLName')
    $dllName.SetAttribute('value', 'BE_Elephants_Standalone_Runtime.dll')
    [void]$subModuleNode.AppendChild($dllName)

    $classType = $manifest.CreateElement('SubModuleClassType')
    $classType.SetAttribute('value', 'BEElephantsStandalone.StandaloneSubModule')
    [void]$subModuleNode.AppendChild($classType)

    $tags = $manifest.CreateElement('Tags')
    $tag1 = $manifest.CreateElement('Tag')
    $tag1.SetAttribute('key', 'DedicatedServerType')
    $tag1.SetAttribute('value', 'none')
    [void]$tags.AppendChild($tag1)
    $tag2 = $manifest.CreateElement('Tag')
    $tag2.SetAttribute('key', 'IsNoRenderModeElement')
    $tag2.SetAttribute('value', 'false')
    [void]$tags.AppendChild($tag2)
    [void]$subModuleNode.AppendChild($tags)
    [void]$subModulesNode.AppendChild($subModuleNode)

    $subModulePath = Join-Path $stage 'SubModule.xml'
    $manifest.Save($subModulePath)

    Write-Step 'Validating copied files'
    [xml]$null = Get-Content -LiteralPath $subModulePath -Raw
    $required = @(
        'AssetPackages\pack0.tpac',
        'bin\Win64_Shipping_Client\BE_Elephants_Standalone_Runtime.dll'
    )
    foreach ($relative in $required) {
        $path = Join-Path $stage $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Fail "Validation failed: required file missing from staged module: $relative"
        }
    }

    $sourcePack = Join-Path $source 'AssetPackages\pack0.tpac'
    $stagePack = Join-Path $stage 'AssetPackages\pack0.tpac'
    if ((Get-Item -LiteralPath $sourcePack).Length -ne (Get-Item -LiteralPath $stagePack).Length) {
        Fail 'Validation failed: copied pack0.tpac size differs from the source.'
    }

    if (Test-Path -LiteralPath $target) {
        Write-Step 'Backing up the existing standalone module'
        Move-Item -LiteralPath $target -Destination $backup
    }

    try {
        Move-Item -LiteralPath $stage -Destination $target
    } catch {
        if ((Test-Path -LiteralPath $backup) -and -not (Test-Path -LiteralPath $target)) {
            Move-Item -LiteralPath $backup -Destination $target
        }
        throw
    }

    Write-Host "`nINSTALLATION SUCCESSFUL" -ForegroundColor Green
    Write-Host "Standalone module: $target"
    Write-Host ''
    Write-Host 'Next: launch the game, enable "Burning Empires - Elephants Standalone",'
    Write-Host 'and test it before disabling or removing the original module.'
    Write-Host 'Keep the original BurningEmpires_Elephants folder until testing is complete.'
    exit 0
}
catch {
    Write-Host "`nINSTALLATION FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($stage -and (Test-Path -LiteralPath $stage)) {
        Write-Host "Staging folder was left for inspection: $stage" -ForegroundColor Yellow
    }
    exit 1
}
