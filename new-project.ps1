[CmdletBinding()]
param(
    [string]$NombreProyecto = "",
    [string]$CodigoProyecto = "",
    [string]$RutaDestino = "",
    [string]$Cliente = "PENDIENTE",
    [string]$BootstrapManifestPath = "",
    [string]$ToolkitRepoPath = "",
    [string]$RepoProyecto = "",
    [string]$WorkspaceCodex = "",
    [string]$RepoPrefix = "obra",
    [switch]$InicializarGit,
    [switch]$Sobrescribir
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($NombreProyecto)) {
    $NombreProyecto = Read-Host "Nombre del proyecto (ej: Urbanizacion Sector 3)"
    if ([string]::IsNullOrWhiteSpace($NombreProyecto)) {
        throw "El nombre del proyecto es obligatorio."
    }
}

if ([string]::IsNullOrWhiteSpace($CodigoProyecto)) {
    $CodigoProyecto = Read-Host "Codigo del proyecto (ej: 535.3)"
    if ([string]::IsNullOrWhiteSpace($CodigoProyecto)) {
        throw "El codigo del proyecto es obligatorio."
    }
}

$plantillaRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($RutaDestino)) {
    $RutaDestino = Split-Path -Parent $plantillaRoot
}

$bootstrapScript = Join-Path $plantillaRoot "scripts\iniciar_proyecto_estandar.ps1"
if (-not (Test-Path -LiteralPath $bootstrapScript)) {
    throw "No se encuentra scripts\iniciar_proyecto_estandar.ps1 en la plantilla."
}

$bootstrapArgs = @{
    CodigoProyecto = $CodigoProyecto
    NombreProyecto = $NombreProyecto
    RutaDestinoRaiz = $RutaDestino
    Cliente = $Cliente
    PlantillaPath = $plantillaRoot
    RepoProyecto = $RepoProyecto
    WorkspaceCodex = $WorkspaceCodex
    ToolkitRepoPath = $ToolkitRepoPath
    RepoPrefix = $RepoPrefix
}

if (-not [string]::IsNullOrWhiteSpace($BootstrapManifestPath)) {
    $bootstrapArgs["BootstrapManifestPath"] = $BootstrapManifestPath
}

if ($InicializarGit) {
    $bootstrapArgs["InicializarGit"] = $true
}

if ($Sobrescribir) {
    $bootstrapArgs["Sobrescribir"] = $true
}

& $bootstrapScript @bootstrapArgs
