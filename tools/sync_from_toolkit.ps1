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

if ([string]::IsNullOrWhiteSpace($ToolkitPath)) {
    $candidateSibling = Join-Path (Split-Path $projectRoot -Parent) "urbanizacion-toolkit"
    $candidateClaudeProjects = Join-Path $env:USERPROFILE `
        "Documents\Claude\Projects\MEJORA CARRETERA GUADALMAR\PROYECTO 535\535.2\535.2.2 Mejora Carretera Guadalmar\urbanizacion-toolkit"

    foreach ($candidate in @($candidateSibling, $candidateClaudeProjects)) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate)) {
            $ToolkitPath = $candidate
            Write-Host "[sync_from_toolkit] Toolkit encontrado en: $ToolkitPath" -ForegroundColor DarkGray
            break
        }
    }
}

try {
    $toolkitResolved = Resolve-Path -LiteralPath $ToolkitPath -ErrorAction Stop
    $toolkitFullPath = $toolkitResolved.Path
}
catch {
    Write-Error "No se puede resolver el toolkit en '$ToolkitPath'. Verifica que urbanizacion-toolkit existe como sibling de este repo."
    exit 1
}

$syncTargets = @(
    @{ Src = "tools\python\bc3_tools.py";                             Dst = "bc3_tools.py" }
    @{ Src = "tools\python\excel_tools.py";                           Dst = "excel_tools.py" }
    @{ Src = "tools\python\mediciones_validator.py";                  Dst = "mediciones_validator.py" }
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
