[CmdletBinding()]
param(
    [switch]$InstallBridge,
    [switch]$InstallMcp,
    [switch]$Launch,
    [string]$RuntimeDirectory = (Join-Path $PSScriptRoot '.runtime\renderdoc-1.47'),
    [string]$ExtensionDirectory = (Join-Path $env:APPDATA 'qrenderdoc\extensions')
)

$ErrorActionPreference = 'Stop'
$manifestPath = Join-Path $PSScriptRoot 'renderdoc-portable\runtime-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$archivePath = Join-Path (Split-Path $manifestPath) $manifest.archive
if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $manifest.sha256) {
    throw 'The runtime ZIP checksum does not match. Download or clone it again.'
}

$runtimePath = [IO.Path]::GetFullPath($RuntimeDirectory)
$runtimePrefix = $runtimePath.TrimEnd('\') + '\'
function Test-RuntimeFiles {
    foreach ($entry in $manifest.files) {
        $filePath = [IO.Path]::GetFullPath((Join-Path $runtimePath $entry.path))
        if (-not $filePath.StartsWith($runtimePrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Invalid runtime manifest path: $($entry.path)"
        }
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) { return $false }
        if ((Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash -ne $entry.sha256) {
            return $false
        }
    }
    return $true
}

if (-not (Test-RuntimeFiles)) {
    New-Item -ItemType Directory -Path $runtimePath -Force | Out-Null
    Expand-Archive -LiteralPath $archivePath -DestinationPath $runtimePath -Force
    if (-not (Test-RuntimeFiles)) { throw 'Extracted runtime verification failed.' }
}

$commandPath = Join-Path $runtimePath 'renderdoccmd.exe'
$versionText = & $commandPath version 2>&1
if ($LASTEXITCODE -ne 0 -or "$versionText" -notmatch 'v1\.47\b') {
    throw 'RenderDoc could not start. Install the Microsoft Visual C++ 2015-2022 runtime (x64; x86 for 32-bit capture).'
}
Write-Output "Verified runtime: $versionText"

if ($InstallBridge) {
    $bridgeSource = Join-Path $PSScriptRoot 'renderdoc-mcp\renderdoc_extension'
    $bridgeTarget = Join-Path $ExtensionDirectory 'renderdoc_mcp_bridge'
    $sourceFiles = @(Get-ChildItem -LiteralPath $bridgeSource -File -Recurse)
    $same = Test-Path -LiteralPath $bridgeTarget -PathType Container
    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($bridgeSource.Length + 1)
        $targetFile = Join-Path $bridgeTarget $relative
        if (-not (Test-Path -LiteralPath $targetFile -PathType Leaf)) { $same = $false; break }
        if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $targetFile).Hash) {
            $same = $false; break
        }
    }
    if (-not $same) {
        if (Test-Path -LiteralPath $bridgeTarget) {
            $backupRoot = Join-Path (Split-Path $ExtensionDirectory) 'extension-backups'
            $backupName = 'renderdoc_mcp_bridge-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
            New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
            $backupPath = Join-Path $backupRoot $backupName
            Copy-Item -LiteralPath $bridgeTarget -Destination $backupPath -Recurse
            Write-Output "Previous extension backed up to: $backupPath"
        }
        foreach ($file in $sourceFiles) {
            $relative = $file.FullName.Substring($bridgeSource.Length + 1)
            $targetFile = Join-Path $bridgeTarget $relative
            New-Item -ItemType Directory -Path (Split-Path $targetFile) -Force | Out-Null
            Copy-Item -LiteralPath $file.FullName -Destination $targetFile -Force
        }
    }
    Write-Output "Extension ready: $bridgeTarget"
    Write-Output 'Enable RenderDoc MCP Bridge in Tools > Manage Extensions.'
}

if ($InstallMcp) {
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        throw 'Install uv first: https://docs.astral.sh/uv/getting-started/installation/'
    }
    $mcpProject = Join-Path $PSScriptRoot 'renderdoc-mcp'
    & uv --directory $mcpProject sync --locked --no-dev
    if ($LASTEXITCODE -ne 0) { throw 'MCP dependency installation failed.' }
    Write-Output "MCP command: uv --directory `"$mcpProject`" run --locked renderdoc-mcp"
}

$guiPath = Join-Path $runtimePath 'qrenderdoc.exe'
Write-Output "RenderDoc executable: $guiPath"
if ($Launch) {
    Start-Process -FilePath $guiPath -WorkingDirectory $runtimePath
}
