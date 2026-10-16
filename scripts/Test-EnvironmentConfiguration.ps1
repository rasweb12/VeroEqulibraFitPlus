[CmdletBinding()]
param(
    [ValidateSet('Api', 'Ai')]
    [string]$Target = 'Api',
    [string]$Path = '.env'
)

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Environment file not found: $Path"
}

$values = @{}
Get-Content -LiteralPath $Path | ForEach-Object {
    if ($_ -match '^\s*([^#=][^=]*)=(.*)$') { $values[$matches[1].Trim()] = $matches[2] }
}

function Require-Value([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($values[$Name])) { throw "Required variable is missing: $Name" }
}

if ($Target -eq 'Api') {
    'Database__ConnectionString', 'Jwt__Issuer', 'Jwt__SigningKey' | ForEach-Object { Require-Value $_ }
    if ([Text.Encoding]::UTF8.GetByteCount($values['Jwt__SigningKey']) -lt 64) {
        throw 'Jwt__SigningKey must contain at least 64 UTF-8 bytes for HS512.'
    }
    Write-Output 'API environment structure is valid. Secret values were not displayed.'
} else {
    'VERO_EQUILIBRAFIT_ENVIRONMENT', 'VERO_EQUILIBRAFIT_INTERNAL_API_KEY', 'VERO_EQUILIBRAFIT_GEMINI_API_KEY' | ForEach-Object { Require-Value $_ }
    if ($values['VERO_EQUILIBRAFIT_ENVIRONMENT'].ToLowerInvariant() -ne 'production') {
        throw 'VERO_EQUILIBRAFIT_ENVIRONMENT must be production for this validation.'
    }
    Write-Output 'AI production environment structure is valid. Secret values were not displayed.'
}
