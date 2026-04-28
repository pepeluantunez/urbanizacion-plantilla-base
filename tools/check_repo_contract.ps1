[CmdletBinding()]
param(
    [string]$ContractPath = '.\CONFIG\repo_contract.json',
    [string]$RootPath = '.',

    [ValidateSet('text', 'json')]
    [string]$OutputFormat = 'text',

    [string]$OutPath,

    [switch]$FailOnErrors
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

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $baseUri = [System.Uri]((Resolve-AbsolutePath -BasePath (Get-Location).Path -TargetPath $BasePath).TrimEnd('\') + '\')
    $targetUri = [System.Uri](Resolve-AbsolutePath -BasePath (Get-Location).Path -TargetPath $TargetPath)
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', '\')
}

function Write-Utf8Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Add-Result {
    param(
        [Parameter(Mandatory = $true)]
        $Bucket,
        [Parameter(Mandatory = $true)]
        [string]$Level,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $Bucket.Add([pscustomobject]@{
        level = $Level
        message = $Message
    })
}

function Test-IgnoredRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [string[]]$IgnoredMarkers = @()
    )

    foreach ($ignoredMarker in @($IgnoredMarkers)) {
        if ([string]::IsNullOrWhiteSpace([string]$ignoredMarker)) {
            continue
        }

        if ($RelativePath.IndexOf([string]$ignoredMarker, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }

    return $false
}

function Test-PolicyDeclaration {
    param(
        [string[]]$PolicyContents,
        [string[]]$Tokens
    )

    foreach ($content in @($PolicyContents)) {
        foreach ($token in @($Tokens)) {
            if ([string]::IsNullOrWhiteSpace([string]$token)) {
                continue
            }

            if ($content.IndexOf([string]$token, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                return $true
            }
        }
    }

    return $false
}

function Get-OptionalArray {
    param(
        [Parameter(Mandatory = $true)]
        $Object,
        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    $property = $Object.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return ,([object[]]@())
    }

    return ,([object[]]@($property.Value))
}

function Build-TextReport {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Payload
    )

    $lines = @()
    $lines += '# Repo contract summary'
    $lines += ''
    $lines += ("Root: {0}" -f $Payload.root)
    $lines += ("Errors: {0}" -f $Payload.errors)
    $lines += ("Warnings: {0}" -f $Payload.warnings)
    $lines += ''

    if (@($Payload.results | Where-Object { $_.level -eq 'ERROR' }).Count -gt 0) {
        $lines += '## Errors'
        foreach ($item in @($Payload.results | Where-Object { $_.level -eq 'ERROR' })) {
            $lines += ("- {0}" -f $item.message)
        }
        $lines += ''
    }

    if (@($Payload.results | Where-Object { $_.level -eq 'WARN' }).Count -gt 0) {
        $lines += '## Warnings'
        foreach ($item in @($Payload.results | Where-Object { $_.level -eq 'WARN' })) {
            $lines += ("- {0}" -f $item.message)
        }
    }

    return ($lines -join [Environment]::NewLine)
}

$rootResolved = Resolve-AbsolutePath -BasePath (Get-Location).Path -TargetPath $RootPath
if (-not (Test-Path -LiteralPath $rootResolved)) {
    throw "No existe la raiz del repo: $RootPath"
}

$contractResolved = Resolve-AbsolutePath -BasePath $rootResolved -TargetPath $ContractPath
if (-not (Test-Path -LiteralPath $contractResolved)) {
    throw "No existe el contrato del repo: $ContractPath"
}

$contract = Get-Content -LiteralPath $contractResolved -Raw -Encoding UTF8 | ConvertFrom-Json
$results = New-Object 'System.Collections.Generic.List[object]'
$ignoredNestedGitMarkers = Get-OptionalArray -Object $contract -PropertyName 'ignored_nested_git_markers'
$forbiddenDirectoryNames = Get-OptionalArray -Object $contract -PropertyName 'forbidden_directory_names'
$requiredAssetPolicyFiles = Get-OptionalArray -Object $contract -PropertyName 'required_asset_policy_files'
$heavyAssetCandidates = Get-OptionalArray -Object $contract -PropertyName 'heavy_asset_candidates'

foreach ($requiredFile in @($contract.required_files)) {
    $path = Join-Path $rootResolved ([string]$requiredFile)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Result -Bucket $results -Level 'ERROR' -Message ("Missing required file: {0}" -f $requiredFile)
    }
}

foreach ($requiredDirectory in @($contract.required_directories)) {
    $path = Join-Path $rootResolved ([string]$requiredDirectory)
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        Add-Result -Bucket $results -Level 'ERROR' -Message ("Missing required directory: {0}" -f $requiredDirectory)
    }
}

foreach ($forbiddenPath in @($contract.forbidden_paths)) {
    $path = Join-Path $rootResolved ([string]$forbiddenPath)
    if (Test-Path -LiteralPath $path) {
        Add-Result -Bucket $results -Level 'ERROR' -Message ("Forbidden path present: {0}" -f $forbiddenPath)
    }
}

$nestedGitDirs = Get-ChildItem -LiteralPath $rootResolved -Recurse -Directory -Force -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -eq '.git' -and
        $_.FullName -ne (Join-Path $rootResolved '.git')
    }

foreach ($nestedGitDir in $nestedGitDirs) {
    $relative = Get-RelativePath -BasePath $rootResolved -TargetPath $nestedGitDir.FullName
    if (-not (Test-IgnoredRelativePath -RelativePath $relative -IgnoredMarkers $ignoredNestedGitMarkers)) {
        Add-Result -Bucket $results -Level 'ERROR' -Message ("Nested repository detected: {0}" -f $relative)
    }
}

if ($forbiddenDirectoryNames.Count -gt 0) {
    $forbiddenMatches = Get-ChildItem -LiteralPath $rootResolved -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -ne $rootResolved -and
            $_.Name -in $forbiddenDirectoryNames
        }

    foreach ($forbiddenMatch in $forbiddenMatches) {
        $relative = Get-RelativePath -BasePath $rootResolved -TargetPath $forbiddenMatch.FullName
        if ([string]::IsNullOrWhiteSpace((Split-Path -Parent $relative))) {
            continue
        }

        if (-not (Test-IgnoredRelativePath -RelativePath $relative -IgnoredMarkers $ignoredNestedGitMarkers)) {
            Add-Result -Bucket $results -Level 'ERROR' -Message ("Forbidden nested directory detected: {0}" -f $relative)
        }
    }
}

$rootMarkdownFiles = @(Get-ChildItem -LiteralPath $rootResolved -File | Where-Object { $_.Extension -eq '.md' })
$rootMarkdownThreshold = [int]$contract.warn_if_root_markdown_count_gt
if ($rootMarkdownFiles.Count -gt $rootMarkdownThreshold) {
    Add-Result -Bucket $results -Level 'WARN' -Message ("Root markdown count is {0}, above warning threshold {1}" -f $rootMarkdownFiles.Count, $rootMarkdownThreshold)
}

foreach ($governanceFile in @($contract.warn_on_root_governance_duplicates)) {
    $path = Join-Path $rootResolved ([string]$governanceFile)
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Add-Result -Bucket $results -Level 'WARN' -Message ("Root governance file should be reviewed for demotion or removal: {0}" -f $governanceFile)
    }
}

if ($heavyAssetCandidates.Count -gt 0) {
    $policyContents = @()
    foreach ($policyFile in $requiredAssetPolicyFiles) {
        $policyAbsolutePath = Join-Path $rootResolved ([string]$policyFile)
        if (Test-Path -LiteralPath $policyAbsolutePath -PathType Leaf) {
            $policyContents += Get-Content -LiteralPath $policyAbsolutePath -Raw -Encoding UTF8
        }
    }

    foreach ($candidate in $heavyAssetCandidates) {
        $candidatePath = ''
        $declarationTokens = @()

        if ($candidate -is [string]) {
            $candidatePath = [string]$candidate
            $declarationTokens = @($candidatePath)
        }
        else {
            if ($null -ne $candidate.path) {
                $candidatePath = [string]$candidate.path
            }

            if ($null -ne $candidate.declaration_keys) {
                $declarationTokens = @($candidate.declaration_keys)
            }

            if ($declarationTokens.Count -eq 0 -and -not [string]::IsNullOrWhiteSpace($candidatePath)) {
                $declarationTokens = @($candidatePath)
            }
        }

        if ([string]::IsNullOrWhiteSpace($candidatePath)) {
            continue
        }

        $candidateAbsolutePath = Join-Path $rootResolved $candidatePath
        if (-not (Test-Path -LiteralPath $candidateAbsolutePath)) {
            continue
        }

        if (-not (Test-PolicyDeclaration -PolicyContents $policyContents -Tokens $declarationTokens)) {
            $policyTargets = if ($requiredAssetPolicyFiles.Count -gt 0) {
                $requiredAssetPolicyFiles -join ', '
            }
            else {
                'policy docs'
            }

            Add-Result -Bucket $results -Level 'WARN' -Message ("Heavy asset candidate present without declaration in {0}: {1}" -f $policyTargets, $candidatePath)
        }
    }
}

$errors = @($results | Where-Object { $_.level -eq 'ERROR' }).Count
$warnings = @($results | Where-Object { $_.level -eq 'WARN' }).Count

$payload = [pscustomobject]@{
    root = $rootResolved
    contract_path = $contractResolved
    role = if ($null -ne $contract.repo_role) { [string]$contract.repo_role } else { '' }
    generated_at = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK')
    errors = $errors
    warnings = $warnings
    results = $results.ToArray()
}

if ($OutputFormat -eq 'json') {
    $content = $payload | ConvertTo-Json -Depth 6
}
else {
    $content = Build-TextReport -Payload $payload
}

if (-not [string]::IsNullOrWhiteSpace($OutPath)) {
    $outAbsolutePath = Resolve-AbsolutePath -BasePath $rootResolved -TargetPath $OutPath
    $outDirectory = Split-Path -Parent $outAbsolutePath
    if (-not [string]::IsNullOrWhiteSpace($outDirectory) -and -not (Test-Path -LiteralPath $outDirectory)) {
        New-Item -ItemType Directory -Path $outDirectory -Force | Out-Null
    }
    Write-Utf8Text -Path $outAbsolutePath -Content $content
}

Write-Output $content

if ($FailOnErrors -and $errors -gt 0) {
    throw ("Repo contract failed: errors={0}, warnings={1}" -f $errors, $warnings)
}
