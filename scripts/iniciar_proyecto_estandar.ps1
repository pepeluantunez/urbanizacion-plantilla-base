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

    [string]$BootstrapManifestPath,

    [string]$RepoProyecto = "",

    [string]$WorkspaceCodex = "",

    [string]$ToolkitRepoPath = "",

    [string]$RepoPrefix = "obra",

    [switch]$InicializarGit,

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

function Convert-ToLongPath {
    param([Parameter(Mandatory = $true)][string]$PathValue)

    $fullPath = [IO.Path]::GetFullPath($PathValue)
    if ($fullPath.StartsWith("\\?\")) {
        return $fullPath
    }

    if ($fullPath.StartsWith("\\")) {
        return "\\?\UNC\" + $fullPath.TrimStart("\")
    }

    return "\\?\" + $fullPath
}

function Ensure-DirectoryExists {
    param([Parameter(Mandatory = $true)][string]$PathValue)

    [void][System.IO.Directory]::CreateDirectory((Convert-ToLongPath -PathValue $PathValue))
}

function Copy-FileRobust {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    $sourceLong = Convert-ToLongPath -PathValue $SourcePath
    $destinationLong = Convert-ToLongPath -PathValue $DestinationPath
    [System.IO.File]::Copy($sourceLong, $destinationLong, $true)
}

function Read-TextFileRobust {
    param([Parameter(Mandatory = $true)][string]$PathValue)

    return [System.IO.File]::ReadAllText((Convert-ToLongPath -PathValue $PathValue), [System.Text.UTF8Encoding]::new($false))
}

function Write-TextFileRobust {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue,
        [Parameter(Mandatory = $true)][string]$Content
    )

    [System.IO.File]::WriteAllText(
        (Convert-ToLongPath -PathValue $PathValue),
        $Content,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function ConvertTo-Slug {
    param([Parameter(Mandatory = $true)][string]$Text)

    $normalized = $Text.Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder

    foreach ($char in $normalized.ToCharArray()) {
        $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($char)
        if ($category -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($char)
        }
    }

    $plain = $builder.ToString().Normalize([Text.NormalizationForm]::FormC).ToLowerInvariant()
    $slug = $plain -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")
    $slug = $slug -replace "-{2,}", "-"
    return $slug
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

function Copy-DirectoryContent {
    param(
        [Parameter(Mandatory = $true)][string]$FromPath,
        [Parameter(Mandatory = $true)][string]$ToPath
    )

    if (-not (Test-Path -LiteralPath $ToPath)) {
        Ensure-DirectoryExists -PathValue $ToPath
    }

    $dirs = Get-ChildItem -LiteralPath $FromPath -Recurse -Directory |
        Where-Object { $_.FullName -notmatch "\\bin\\|\\obj\\|\\\.git\\" } |
        Sort-Object FullName
    foreach ($dir in $dirs) {
        $relativeDir = $dir.FullName.Substring($FromPath.Length).TrimStart("\")
        $targetDir = Join-Path $ToPath $relativeDir
        if (-not (Test-Path -LiteralPath $targetDir)) {
            Ensure-DirectoryExists -PathValue $targetDir
        }
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
            Ensure-DirectoryExists -PathValue $targetDir
        }
        Copy-FileRobust -SourcePath $file.FullName -DestinationPath $targetFile
    }
}

function Copy-TemplateEntry {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$DestinationRoot,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $cleanRelative = $RelativePath.TrimStart("\", "/")
    $sourceEntry = Join-Path $SourceRoot $cleanRelative

    if (-not (Test-Path -LiteralPath $sourceEntry)) {
        throw "La ruta de plantilla no existe y no se puede copiar: $cleanRelative"
    }

    $destinationEntry = Join-Path $DestinationRoot $cleanRelative
    $sourceItem = Get-Item -LiteralPath $sourceEntry

    if ($sourceItem.PSIsContainer) {
        Copy-DirectoryContent -FromPath $sourceEntry -ToPath $destinationEntry
        return
    }

    $targetDir = Split-Path -Parent $destinationEntry
    if (-not (Test-Path -LiteralPath $targetDir)) {
        Ensure-DirectoryExists -PathValue $targetDir
    }
    Copy-FileRobust -SourcePath $sourceEntry -DestinationPath $destinationEntry
}

function Copy-TemplateContent {
    param(
        [Parameter(Mandatory = $true)][string]$FromPath,
        [Parameter(Mandatory = $true)][string]$ToPath,
        [string[]]$IncludePaths
    )

    if ($IncludePaths -and $IncludePaths.Count -gt 0) {
        foreach ($relativePath in $IncludePaths | Select-Object -Unique) {
            Copy-TemplateEntry -SourceRoot $FromPath -DestinationRoot $ToPath -RelativePath $relativePath
        }
        return
    }

    Copy-DirectoryContent -FromPath $FromPath -ToPath $ToPath
}

function Get-BootstrapIncludePaths {
    param([string]$ManifestPath)

    if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
        return @()
    }

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "No existe el manifiesto de bootstrap: $ManifestPath"
    }

    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    if ($null -eq $manifest.include_paths) {
        return @()
    }

    return @($manifest.include_paths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Sync-ToolkitIfRequested {
    param(
        [Parameter(Mandatory = $true)][string]$ProyectoPath,
        [string]$ToolkitPath
    )

    $syncScriptPath = Join-Path $ProyectoPath "tools\sync_from_toolkit.ps1"
    if (-not (Test-Path -LiteralPath $syncScriptPath)) {
        Write-Warning "No existe tools\sync_from_toolkit.ps1 en el proyecto bootstrap."
        return $false
    }

    if (-not [string]::IsNullOrWhiteSpace($ToolkitPath)) {
        $resolvedToolkitPath = Resolve-FullPath -PathValue $ToolkitPath
        & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScriptPath -ToolkitPath $resolvedToolkitPath
    }
    else {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScriptPath
    }
    return $true
}

try {
    $plantillaFullPath = Resolve-FullPath -PathValue $PlantillaPath
}
catch {
    throw "No existe la plantilla en '$PlantillaPath'. Revisa la ruta."
}

if ([string]::IsNullOrWhiteSpace($BootstrapManifestPath)) {
    $defaultManifestPath = Join-Path $plantillaFullPath "CONFIG\bootstrap.copy-manifest.json"
    if (Test-Path -LiteralPath $defaultManifestPath) {
        $BootstrapManifestPath = $defaultManifestPath
    }
}

if (-not (Test-Path -LiteralPath $RutaDestinoRaiz)) {
    throw "La ruta destino raiz no existe: $RutaDestinoRaiz"
}

$destinoRaizFullPath = Resolve-FullPath -PathValue $RutaDestinoRaiz
$codigoSafe = Sanitize-PathName -Name $CodigoProyecto
$nombreSafe = Sanitize-PathName -Name $NombreProyecto
$folderName = "$codigoSafe - $nombreSafe"
$proyectoPath = Join-Path $destinoRaizFullPath $folderName

$repoSlug = if (-not [string]::IsNullOrWhiteSpace($RepoProyecto)) {
    $RepoProyecto
}
elseif (-not [string]::IsNullOrWhiteSpace($RepoPrefix)) {
    "$RepoPrefix-$(ConvertTo-Slug -Text $CodigoProyecto)-$(ConvertTo-Slug -Text $NombreProyecto)"
}
else {
    "$(ConvertTo-Slug -Text $CodigoProyecto)-$(ConvertTo-Slug -Text $NombreProyecto)"
}

$workspaceName = if (-not [string]::IsNullOrWhiteSpace($WorkspaceCodex)) {
    $WorkspaceCodex
}
else {
    $folderName
}

if (Test-Path -LiteralPath $proyectoPath) {
    if (-not $Sobrescribir) {
        throw "Ya existe '$proyectoPath'. Usa -Sobrescribir para continuar."
    }
}
else {
    New-Item -ItemType Directory -Path $proyectoPath -Force | Out-Null
}

$includePaths = Get-BootstrapIncludePaths -ManifestPath $BootstrapManifestPath
Copy-TemplateContent -FromPath $plantillaFullPath -ToPath $proyectoPath -IncludePaths $includePaths

$fechaText = $FechaInicio.ToString("yyyy-MM-dd")
$tokenMap = @{
    "{{CODIGO_PROYECTO}}" = $CodigoProyecto
    "{{NOMBRE_PROYECTO}}" = $NombreProyecto
    "{{CLIENTE}}" = $Cliente
    "{{FECHA_INICIO}}" = $fechaText
    "{{NOMBRE_CARPETA_PROYECTO}}" = $folderName
    "{{REPO_PROYECTO}}" = $repoSlug
    "{{WORKSPACE_CODEX}}" = $workspaceName
}

$textExtensions = @(".md", ".txt", ".json", ".ps1", ".csv")
$textFiles = Get-ChildItem -LiteralPath $proyectoPath -Recurse -File |
    Where-Object { $textExtensions -contains $_.Extension.ToLowerInvariant() }

foreach ($file in $textFiles) {
    $content = Read-TextFileRobust -PathValue $file.FullName
    $updated = $content
    foreach ($token in $tokenMap.Keys) {
        $updated = $updated.Replace($token, $tokenMap[$token])
    }
    if ($updated -ne $content) {
        Write-TextFileRobust -PathValue $file.FullName -Content $updated
    }
}

if ($InicializarGit) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "No se encontro git en PATH y no se puede inicializar el repositorio."
    }

    if (-not (Test-Path -LiteralPath (Join-Path $proyectoPath ".git"))) {
        & git -C $proyectoPath init --initial-branch=main | Out-Null
    }
}

$toolkitSynced = $false
try {
    $toolkitSynced = Sync-ToolkitIfRequested -ProyectoPath $proyectoPath -ToolkitPath $ToolkitRepoPath
}
catch {
    Write-Warning "No se pudo sincronizar el toolkit durante el bootstrap: $_"
}

Write-Host ""
Write-Host "Proyecto creado correctamente:" -ForegroundColor Green
Write-Host "  $proyectoPath"
Write-Host ""
Write-Host "Repo Git sugerido:"
Write-Host "  $repoSlug"
Write-Host ""
Write-Host "Siguientes pasos recomendados:"
Write-Host "  1) Revisar CONFIG\project_identity.json y CONFIG\proyecto.template.json"
Write-Host "  2) Completar MAPA_PROYECTO.md y FUENTES_MAESTRAS.md"
Write-Host "  3) Completar CHECKLISTS\01_INICIO.md"
if ($toolkitSynced) {
    Write-Host "  4) Verificar los scripts compartidos sincronizados en tools\"
    Write-Host "  5) Abrir el proyecto en Codex y arrancar desde AGENTS.md"
}
else {
    Write-Host "  4) Ejecutar manualmente powershell -File .\tools\sync_from_toolkit.ps1"
    Write-Host "  5) Abrir el proyecto en Codex y arrancar desde AGENTS.md"
}
