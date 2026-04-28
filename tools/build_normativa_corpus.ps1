[CmdletBinding()]
param(
    [string]$SourceRoot = ".\NORMATIVA\00_fuentes_pdf",
    [string]$NormativaRoot = ".\NORMATIVA",
    [string]$CatalogPath = "",
    [string]$NameFilter = "",
    [int]$Limit = 0,
    [switch]$SkipExisting
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Resolve-PythonCommand {
    $candidates = @(
        (Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\Python\Python312\python.exe"),
        "py",
        "python"
    )

    foreach ($candidate in $candidates) {
        try {
            if (($candidate -in @('py', 'python')) -or (Test-Path -LiteralPath $candidate)) {
                return $candidate
            }
        }
        catch {
        }
    }

    throw "No se ha encontrado un interprete Python util para extraer normativa."
}

$python = Resolve-PythonCommand
$scriptPath = Join-Path $PSScriptRoot 'build_normativa_corpus.py'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "No existe el builder canonico: $scriptPath"
}

$arguments = @($scriptPath, '--source-root', $SourceRoot, '--normativa-root', $NormativaRoot)
if (-not [string]::IsNullOrWhiteSpace($CatalogPath)) {
    $arguments += @('--catalog-path', $CatalogPath)
}
if (-not [string]::IsNullOrWhiteSpace($NameFilter)) {
    $arguments += @('--name-filter', $NameFilter)
}
if ($Limit -gt 0) {
    $arguments += @('--limit', [string]$Limit)
}
if ($SkipExisting) {
    $arguments += '--skip-existing'
}

if ($python -eq 'py') {
    & $python -3 @arguments
}
else {
    & $python @arguments
}

if ($LASTEXITCODE -ne 0) {
    throw "La extraccion normativa ha fallado con exit code $LASTEXITCODE."
}
