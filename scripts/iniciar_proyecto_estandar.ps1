param(
    [Parameter(Mandatory = $true)]
    [string]$CodigoProyecto,

    [Parameter(Mandatory = $true)]
    [string]$NombreProyecto,

    [Parameter(Mandatory = $true)]
    [string]$RutaDestinoRaiz,

    [string]$Cliente = "PENDIENTE",

    [datetime]$FechaInicio = (Get-Date),

    [string]$PlantillaPath,

    [string]$RepoProyecto = "",

    [string]$WorkspaceCodex = "",

    [switch]$Sobrescribir
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($PlantillaPath)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Split-Path -Parent $scriptRoot
    $PlantillaPath = $projectRoot
}

function Resolve-FullPath {
    param([Parameter(Mandatory = $true)][string]$PathValue)
    $resolved = Resolve-Path -LiteralPath $PathValue -ErrorAction Stop
    return $resolved.Path
}

function Sanitize-PathName {
    param([Parameter(Mandatory = $true)][string]$Name)
    $invalid = [IO.Path]::GetInvalidFileNameChars()
    $safe = $Name
    foreach ($ch in $invalid) {
        $safe = $safe.Replace($ch, "-")
    }
    return ($safe -replace "\s{2,}", " ").Trim()
}

function Copy-TemplateContent {
    param(
        [Parameter(Mandatory = $true)][string]$FromPath,
        [Parameter(Mandatory = $true)][string]$ToPath
    )

    $manifestPath = Join-Path $FromPath "CONFIG\bootstrap.copy-manifest.json"
    if (Test-Path -LiteralPath $manifestPath) {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        foreach ($entry in $manifest.include_paths) {
            $sourceEntry = Join-Path $FromPath $entry
            if (-not (Test-Path -LiteralPath $sourceEntry)) {
                continue
            }

            $targetEntry = Join-Path $ToPath $entry
            $targetParent = Split-Path -Parent $targetEntry
            if ($targetParent -and -not (Test-Path -LiteralPath $targetParent)) {
                New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            }

            $sourceItem = Get-Item -LiteralPath $sourceEntry
            if ($sourceItem -is [System.IO.DirectoryInfo]) {
                New-Item -ItemType Directory -Path $targetEntry -Force | Out-Null
                Copy-Item -Path (Join-Path $sourceEntry '*') -Destination $targetEntry -Recurse -Force
            } else {
                Copy-Item -LiteralPath $sourceEntry -Destination $targetEntry -Force
            }
        }

        return
    }

    $files = Get-ChildItem -LiteralPath $FromPath -Recurse -File |
        Where-Object {
            $_.Name -notlike "~$*" -and
            $_.Extension -notin @(".tmp", ".bak") -and
            $_.FullName -notmatch "\\bin\\|\\obj\\|\\\.git\\"
        }

    foreach ($file in $files) {
        $relative = $file.FullName.Substring($FromPath.Length).TrimStart("\")
        $targetFile = Join-Path $ToPath $relative
        $targetDir = Split-Path -Parent $targetFile
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $file.FullName -Destination $targetFile -Force
    }

    $dirs = Get-ChildItem -LiteralPath $FromPath -Recurse -Directory |
        Where-Object { $_.FullName -notmatch "\\bin\\|\\obj\\|\\\.git\\" }
    foreach ($dir in $dirs) {
        $relativeDir = $dir.FullName.Substring($FromPath.Length).TrimStart("\")
        $targetDir = Join-Path $ToPath $relativeDir
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
    }
}

try {
    $plantillaFullPath = Resolve-FullPath -PathValue $PlantillaPath
} catch {
    throw "No existe la plantilla en '$PlantillaPath'. Revisa la ruta."
}

if (-not (Test-Path -LiteralPath $RutaDestinoRaiz)) {
    throw "La ruta destino raiz no existe: $RutaDestinoRaiz"
}

$destinoRaizFullPath = Resolve-FullPath -PathValue $RutaDestinoRaiz
$codigoSafe = Sanitize-PathName -Name $CodigoProyecto
$nombreSafe = Sanitize-PathName -Name $NombreProyecto
$folderName = "$codigoSafe - $nombreSafe"
$proyectoPath = Join-Path $destinoRaizFullPath $folderName

if (Test-Path -LiteralPath $proyectoPath) {
    if (-not $Sobrescribir) {
        throw "Ya existe '$proyectoPath'. Usa -Sobrescribir para continuar."
    }
} else {
    New-Item -ItemType Directory -Path $proyectoPath -Force | Out-Null
}

Copy-TemplateContent -FromPath $plantillaFullPath -ToPath $proyectoPath

$fechaText = $FechaInicio.ToString("yyyy-MM-dd")
$tokenMap = @{
    "{{CODIGO_PROYECTO}}" = $CodigoProyecto
    "{{NOMBRE_PROYECTO}}" = $NombreProyecto
    "{{CLIENTE}}" = $Cliente
    "{{FECHA_INICIO}}" = $fechaText
    "{{NOMBRE_CARPETA_PROYECTO}}" = $folderName
    "{{REPO_PROYECTO}}" = $RepoProyecto
    "{{WORKSPACE_CODEX}}" = $WorkspaceCodex
}

$textExtensions = @(".md", ".txt", ".json", ".ps1", ".csv")
$textFiles = Get-ChildItem -LiteralPath $proyectoPath -Recurse -File |
    Where-Object { $textExtensions -contains $_.Extension.ToLowerInvariant() }

foreach ($file in $textFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $updated = $content
    foreach ($token in $tokenMap.Keys) {
        $updated = $updated.Replace($token, $tokenMap[$token])
    }
    if ($updated -ne $content) {
        Set-Content -LiteralPath $file.FullName -Value $updated -Encoding UTF8
    }
}

Write-Host ""
Write-Host "Proyecto creado correctamente:" -ForegroundColor Green
Write-Host "  $proyectoPath"
Write-Host ""
Write-Host "Siguientes pasos recomendados:"
Write-Host "  1) Revisar $($folderName)\\CONFIG\\proyecto.template.json"
Write-Host "  2) Completar CHECKLISTS\\01_INICIO.md"
Write-Host "  3) Empezar el trabajo en base a ESTANDARES.md"
