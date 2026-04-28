[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    [string]$NormativaRoot = ".\NORMATIVA",
    [int]$MaxResults = 10,
    [switch]$CatalogOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Resolve-AbsolutePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    if ([System.IO.Path]::IsPathRooted($TargetPath)) {
        return [System.IO.Path]::GetFullPath($TargetPath)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $TargetPath))
}

function Get-MatchScore {
    param(
        [Parameter(Mandatory = $true)]
        $Item,
        [Parameter(Mandatory = $true)]
        [string[]]$Terms,
        [Parameter(Mandatory = $true)]
        [string]$TextCorpus
    )

    $score = 0
    $catalogHaystack = @(
        [string]$Item.id,
        [string]$Item.title,
        [string]$Item.category,
        [string]$Item.domain,
        [string]$Item.pdf_path,
        [string]$Item.text_path,
        @($Item.keywords) -join ' '
    ) -join ' '

    foreach ($term in $Terms) {
        if ($catalogHaystack -match [regex]::Escape($term)) {
            $score += 5
        }
        if (-not [string]::IsNullOrWhiteSpace($TextCorpus) -and $TextCorpus -match [regex]::Escape($term)) {
            $score += 1
        }
    }

    return $score
}

function Get-Snippet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [string[]]$Terms
    )

    foreach ($term in $Terms) {
        $index = $Text.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase)
        if ($index -ge 0) {
            $start = [Math]::Max(0, $index - 80)
            $length = [Math]::Min(220, $Text.Length - $start)
            return ($Text.Substring($start, $length) -replace '\s+', ' ').Trim()
        }
    }

    return ''
}

$normativaRootAbsolutePath = Resolve-AbsolutePath -BasePath (Get-Location).Path -TargetPath $NormativaRoot
$catalogPath = Join-Path $normativaRootAbsolutePath 'catalog.json'
if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
    throw "No existe el catalogo de normativa: $catalogPath"
}

$catalog = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
$terms = @($Query -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($terms.Count -eq 0) {
    throw 'La consulta no puede quedar vacia.'
}

$matches = foreach ($item in @($catalog.items)) {
    $textCorpus = ''
    if (-not $CatalogOnly) {
        $textPath = Resolve-AbsolutePath -BasePath $normativaRootAbsolutePath -TargetPath ([string]$item.text_path)
        if (Test-Path -LiteralPath $textPath -PathType Leaf) {
            $textCorpus = Get-Content -LiteralPath $textPath -Raw -Encoding UTF8
        }
    }

    $score = Get-MatchScore -Item $item -Terms $terms -TextCorpus $textCorpus
    if ($score -le 0) {
        continue
    }

    [pscustomobject]@{
        score = $score
        id = [string]$item.id
        title = [string]$item.title
        category = [string]$item.category
        domain = [string]$item.domain
        pdf_path = [string]$item.pdf_path
        text_path = [string]$item.text_path
        snippet = if ($CatalogOnly) { '' } else { Get-Snippet -Text $textCorpus -Terms $terms }
    }
}

$top = @(
    $matches |
        Sort-Object -Property @(
            @{ Expression = 'score'; Descending = $true },
            @{ Expression = 'id'; Descending = $false }
        ) |
        Select-Object -First $MaxResults
)
if ($top.Count -eq 0) {
    Write-Output ("Sin coincidencias para: {0}" -f $Query)
    return
}

Write-Output ("Resultados para: {0}" -f $Query)
foreach ($match in $top) {
    Write-Output ("- [{0}] {1}" -f $match.id, $match.title)
    Write-Output ("  categoria={0} dominio={1}" -f $match.category, $match.domain)
    Write-Output ("  pdf={0}" -f $match.pdf_path)
    Write-Output ("  texto={0}" -f $match.text_path)
    if (-not [string]::IsNullOrWhiteSpace($match.snippet)) {
        Write-Output ("  snippet={0}" -f $match.snippet)
    }
}
