<#
.SYNOPSIS
    Sincroniza herramientas compartidas desde urbanizacion-toolkit al tools/ local.

.DESCRIPTION
    Copia los scripts Python canonicos y varios checks PowerShell compartidos desde
    urbanizacion-toolkit al directorio tools/ del proyecto.
    Ejecutar al arrancar el proyecto y cuando se actualice el toolkit.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\sync_from_toolkit.ps1
#>

[CmdletBinding()]
param(
    [string]$ToolkitPath = ""
)

$ErrorActionPreference = "Stop"

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

function Resolve-ToolkitRepoPath {
    param(
        [string]$PreferredPath,
        [string]$StartPath
    )

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        try {
            return (Resolve-Path -LiteralPath $PreferredPath -ErrorAction Stop).Path
        }
        catch {
        }
    }

    $repoName = "urbanizacion-toolkit"
    $startFullPath = (Resolve-Path -LiteralPath $StartPath -ErrorAction Stop).Path
    $cursor = $startFullPath

    while (-not [string]::IsNullOrWhiteSpace($cursor)) {
        $item = Get-Item -LiteralPath $cursor -ErrorAction SilentlyContinue
        if ($item -and $item.PSIsContainer -and $item.Name -ieq $repoName) {
            return $item.FullName
        }

        $parent = Split-Path -Parent $cursor
        if (-not [string]::IsNullOrWhiteSpace($parent)) {
            $sibling = Join-Path $parent $repoName
            if (Test-Path -LiteralPath $sibling) {
                return (Resolve-Path -LiteralPath $sibling -ErrorAction Stop).Path
            }
        }

        if ($parent -eq $cursor) {
            break
        }

        $cursor = $parent
    }

    $fallbackRoots = @(
        (Join-Path $env:USERPROFILE "Documents\Claude\Projects"),
        (Join-Path $env:USERPROFILE "Documents\Claude")
    ) | Select-Object -Unique

    foreach ($root in $fallbackRoots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        $match = Get-ChildItem -LiteralPath $root -Directory -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ieq $repoName } |
            Select-Object -First 1

        if ($match) {
            return $match.FullName
        }
    }

    throw "No se puede resolver el toolkit desde '$startFullPath'."
}

if ([string]::IsNullOrWhiteSpace($ToolkitPath)) {
    $ToolkitPath = Resolve-ToolkitRepoPath -StartPath $projectRoot
    Write-Host "[sync_from_toolkit] Toolkit encontrado en: $ToolkitPath" -ForegroundColor DarkGray
}

try {
    $toolkitFullPath = Resolve-ToolkitRepoPath -PreferredPath $ToolkitPath -StartPath $projectRoot
}
catch {
    Write-Error "No se puede resolver el toolkit en '$ToolkitPath'. Verifica que urbanizacion-toolkit existe como sibling de este repo."
    exit 1
}

$syncTargets = @(
    @{ Src = "tools\python\bc3_tools.py";                             Dst = "bc3_tools.py" }
    @{ Src = "tools\python\excel_tools.py";                           Dst = "excel_tools.py" }
    @{ Src = "tools\python\mediciones_validator.py";                  Dst = "mediciones_validator.py" }
    @{ Src = "tools\automation\resolve_ecosystem_repo.ps1";           Dst = "resolve_ecosystem_repo.ps1" }
    @{ Src = "tools\automation\find_in_workspace.ps1";                Dst = "find_in_workspace.ps1" }
    @{ Src = "tools\automation\check_ecosystem_alignment.ps1";        Dst = "check_ecosystem_alignment.ps1" }
    @{ Src = "tools\automation\check_machine_guard.ps1";              Dst = "check_machine_guard.ps1" }
    @{ Src = "tools\bc3\check_bc3_integrity.ps1";                     Dst = "check_bc3_integrity.ps1" }
    @{ Src = "tools\bc3\check_bc3_import_parity.ps1";                 Dst = "check_bc3_import_parity.ps1" }
    @{ Src = "tools\office\check_docx_tables_consistency.ps1";        Dst = "check_docx_tables_consistency.ps1" }
    @{ Src = "tools\office\check_excel_formula_guard.ps1";            Dst = "check_excel_formula_guard.ps1" }
    @{ Src = "tools\office\check_office_mojibake.ps1";                Dst = "check_office_mojibake.ps1" }
    @{ Src = "tools\traceability\check_traceability_consistency.ps1"; Dst = "check_traceability_consistency.ps1" }
    @{ Src = "tools\traceability\run_traceability_profile.ps1";       Dst = "run_traceability_profile.ps1" }
    @{ Src = "tools\learning\skill_error_logger.ps1";                 Dst = "skill_error_logger.ps1" }
    @{ Src = "tools\learning\skill_self_improve.ps1";                 Dst = "skill_self_improve.ps1" }
)

$localTools = Join-Path $projectRoot "tools"
if (-not (Test-Path -LiteralPath $localTools)) {
    New-Item -ItemType Directory -Path $localTools -Force | Out-Null
}

$ok = 0
$warn = 0

foreach ($entry in $syncTargets) {
    $srcPath = Join-Path $toolkitFullPath $entry.Src
    $dstPath = Join-Path $localTools $entry.Dst

    if (-not (Test-Path -LiteralPath $srcPath)) {
        Write-Warning ("  [AVISO] No encontrado en toolkit: {0} - se omite." -f $entry.Src)
        $warn++
        continue
    }

    Copy-Item -LiteralPath $srcPath -Destination $dstPath -Force
    Write-Host ("  [OK] {0} -> tools\{1}" -f $entry.Src, $entry.Dst) -ForegroundColor Green
    $ok++
}

Write-Host ""
if ($warn -eq 0) {
    Write-Host "Sincronizacion completada: $ok archivo(s) copiado(s)." -ForegroundColor Green
}
else {
    Write-Host "Sincronizacion parcial: $ok copiado(s), $warn no encontrado(s) en toolkit." -ForegroundColor Yellow
    Write-Host 'Verifica que urbanizacion-toolkit esta actualizado y contiene tools\python, tools\bc3, tools\office, tools\traceability y tools\learning.'
}
