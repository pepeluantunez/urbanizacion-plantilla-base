# nuevo_proyecto.ps1
# Script de arranque rapido para crear un proyecto de urbanizacion nuevo.
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File .\nuevo_proyecto.ps1
#
# Pide los datos minimos del proyecto y genera la carpeta completa en Projects/.

$ErrorActionPreference = "Stop"

$PlantillaPath   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectsRoot    = Split-Path -Parent $PlantillaPath
$ToolkitPath     = Join-Path $ProjectsRoot "urbanizacion-toolkit"
$BootstrapScript = Join-Path $PlantillaPath "scripts\iniciar_proyecto_estandar.ps1"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  NUEVO PROYECTO DE URBANIZACION"           -ForegroundColor Cyan
Write-Host "  Ecosistema 535 — JL Antunez"              -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- Recoger datos minimos ---
$CodigoProyecto = Read-Host "Codigo del proyecto (ej: 535.3.1)"
if ([string]::IsNullOrWhiteSpace($CodigoProyecto)) {
    Write-Error "El codigo de proyecto es obligatorio."
    exit 1
}

$NombreProyecto = Read-Host "Nombre del proyecto (ej: Proyecto de Urbanizacion - Sector Norte)"
if ([string]::IsNullOrWhiteSpace($NombreProyecto)) {
    Write-Error "El nombre de proyecto es obligatorio."
    exit 1
}

$Cliente = Read-Host "Cliente [PENDIENTE]"
if ([string]::IsNullOrWhiteSpace($Cliente)) { $Cliente = "PENDIENTE" }

$RutaDestino = Read-Host "Carpeta raiz donde crear el proyecto [$ProjectsRoot]"
if ([string]::IsNullOrWhiteSpace($RutaDestino)) { $RutaDestino = $ProjectsRoot }

Write-Host ""
Write-Host "Resumen:" -ForegroundColor Yellow
Write-Host "  Codigo   : $CodigoProyecto"
Write-Host "  Nombre   : $NombreProyecto"
Write-Host "  Cliente  : $Cliente"
Write-Host "  Destino  : $RutaDestino\$CodigoProyecto - $NombreProyecto"
Write-Host "  Plantilla: $PlantillaPath"
Write-Host "  Toolkit  : $ToolkitPath"
Write-Host ""

$confirm = Read-Host "Confirmar creacion? (S/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "Cancelado." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Creando proyecto..." -ForegroundColor Green

& powershell -NoProfile -ExecutionPolicy Bypass -File $BootstrapScript `
    -CodigoProyecto $CodigoProyecto `
    -NombreProyecto $NombreProyecto `
    -Cliente $Cliente `
    -RutaDestinoRaiz $RutaDestino `
    -PlantillaPath $PlantillaPath `
    -ToolkitRepoPath $ToolkitPath `
    -InicializarGit

if ($LASTEXITCODE -ne 0) {
    Write-Error "El bootstrap fallo con codigo $LASTEXITCODE."
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  PROYECTO CREADO"                           -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Proximos pasos:" -ForegroundColor Yellow
Write-Host "  1. Abre la carpeta del proyecto en Claude / Cowork"
Write-Host "  2. Lee MAPA_PROYECTO.md para orientarte"
Write-Host "  3. Ejecuta: powershell -File .\tools\sync_from_toolkit.ps1"
Write-Host "  4. Revisa CONFIG\project_identity.json y completa los datos"
Write-Host "  5. Arranca desde AGENTS.md"
Write-Host ""
