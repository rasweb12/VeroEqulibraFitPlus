param(
  [string]$SourcePath = 'D:\Curso\APP\Videos',
  [string]$OutputPath = 'docs\inventario_videos.csv'
)

$resolvedOutput = Join-Path (Get-Location) $OutputPath
$rows = Get-ChildItem -LiteralPath $SourcePath -File -Recurse | Sort-Object FullName | ForEach-Object {
  $hash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
  [pscustomobject]@{
    Name = $_.Name
    SourcePath = $_.FullName
    Extension = $_.Extension
    SizeBytes = $_.Length
    LastWriteTimeUtc = $_.LastWriteTimeUtc.ToString('O')
    Sha256 = $hash.Hash
    PossibleExercise = ($_.BaseName -replace ' \(\d+\)$', '')
    Source = 'MuscleWiki reference reported by user; provenance unverified'
    LicenseHolder = 'Unknown'
    RedistributionRight = 'Unknown'
    AttributionRequired = 'Unknown'
    AuthorizationStatus = 'Undefined - excluded from distributable builds'
    Duration = 'Not inspected: ffprobe unavailable'
    Resolution = 'Not inspected: ffprobe unavailable'
    Codec = 'Not inspected: ffprobe unavailable'
  }
}
$rows | Export-Csv -LiteralPath $resolvedOutput -NoTypeInformation -Encoding utf8
Write-Output "Created $resolvedOutput with $($rows.Count) rows."
