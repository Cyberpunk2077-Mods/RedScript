param (
    [Parameter(Mandatory=$true)]
    [string]$archiveName
)

$ErrorActionPreference = 'Stop'

foreach ($binary in @('scc.exe', 'scc_lib.dll', 'redscript-cli.exe')) {
    if (-not (Test-Path -LiteralPath "./target/release/$binary" -PathType Leaf)) {
        throw "$binary not found in target/release. Please ensure you have built it."
    }
}

$workingDir = (Get-Location).Path
if ($env:RUNNER_TEMP) {
    $tempDir = $env:RUNNER_TEMP
} else {
    $tempDir = $env:TEMP
}
$stagingDir = Join-Path ([IO.Path]::GetFullPath($tempDir)) ("redscript-archive-" + [guid]::NewGuid().ToString('N'))
$toolsDir = @($stagingDir, 'engine', 'tools') -join [IO.Path]::DirectorySeparatorChar

try {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
    Copy-Item -Path "./assets/windows/archive/*" -Destination $stagingDir -Recurse -Force
    Copy-Item -Path "./target/release/scc.exe" -Destination $toolsDir
    Copy-Item -Path "./target/release/scc_lib.dll" -Destination $toolsDir
    Copy-Item -Path "./target/release/redscript-cli.exe" -Destination $workingDir
    Compress-Archive -Path "$stagingDir/*" -DestinationPath "$workingDir/$archiveName" -Force
} finally {
    if (Test-Path -LiteralPath $stagingDir) {
        Remove-Item -LiteralPath $stagingDir -Recurse -Force
    }
}
