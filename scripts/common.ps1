#Requires -Version 5.1
<#
.SYNOPSIS
    Shared helpers for the C64GameEngine docker scripts (Windows / PowerShell).
#>

Set-StrictMode -Version Latest

function Write-C64Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-C64Ok   { param([string]$Message) Write-Host "[ OK ] $Message" -ForegroundColor Green }
function Write-C64Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-C64Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

<#
.SYNOPSIS
    Verifies that Docker is installed and the daemon is reachable.
#>
function Test-C64Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker non e' installato: https://docs.docker.com/get-docker/"
    }

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & docker info *> $null
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }

    if ($exitCode -ne 0) {
        throw "Docker daemon non raggiungibile. Avvia Docker Desktop e riprova."
    }
}

<#
.SYNOPSIS
    Returns the command to use for Docker Compose (v2 preferred, v1 as fallback).
#>
function Get-C64ComposeCommand {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & docker compose version *> $null
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }

    if ($exitCode -eq 0) { return @('docker', 'compose') }

    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        return @('docker-compose')
    }

    throw "Docker Compose non trovato (installa Docker Desktop o il plugin compose)."
}

<#
.SYNOPSIS
    Converts a captured console line (string or ErrorRecord) into plain text.
.DESCRIPTION
    Native commands (docker compose) write their progress on stderr: PowerShell
    wraps those lines into ErrorRecords whose default rendering is a verbose
    error block. This helper extracts the raw message instead.
#>
function ConvertTo-C64Text {
    param($Record)

    if ($Record -is [System.Management.Automation.ErrorRecord]) {
        $message = $Record.Exception.Message
        if ($message) { return $message.TrimEnd() }
        return ($Record | Out-String).TrimEnd()
    }

    return ($Record | Out-String).TrimEnd()
}

<#
.SYNOPSIS
    Runs a docker compose command.
.PARAMETER Arguments
    The arguments passed to "docker compose".
.PARAMETER Capture
    When set the output is returned instead of being printed.
#>
function Invoke-C64Compose {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$Capture
    )

    $compose = Get-C64ComposeCommand
    $full = @($compose) + $Arguments

    $exe = $full[0]
    if ($full.Count -gt 1) {
        $rest = @($full[1..($full.Count - 1)])
    } else {
        $rest = @()
    }

    # "Continue" keeps the stderr lines (merged into the output) instead of
    # letting PowerShell raise them as terminating errors.
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $exe @rest 2>&1
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    $exitCode = $LASTEXITCODE

    if (-not $Capture) {
        foreach ($line in $output) {
            $text = ConvertTo-C64Text $line
            if ($text) { Write-Host $text }
        }
    }

    if ($exitCode -ne 0) {
        throw "docker compose $($Arguments -join ' ') ha fallito (exit code $exitCode)."
    }

    if ($Capture) { return $output }
}

<#
.SYNOPSIS
    Loads the variables of a .env file into the process environment.
#>
function Import-C64EnvFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return }

    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
        if ($trimmed -notmatch '=') { continue }

        $key, $value = $trimmed -split '=', 2
        $key = $key.Trim()
        $value = $value.Trim().Trim('"').Trim("'")
        if (-not [Environment]::GetEnvironmentVariable($key)) {
            [Environment]::SetEnvironmentVariable($key, $value)
        }
    }
}

<#
.SYNOPSIS
    Waits until the container is healthy (or running when no healthcheck exists).
#>
function Wait-C64Container {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [int]$TimeoutSeconds = 120
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $status = 'unknown'

    while ((Get-Date) -lt $deadline) {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $status = (& docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' $Name 2>$null | Out-String).Trim()
        } finally {
            $ErrorActionPreference = $previousPreference
        }
        if ($LASTEXITCODE -ne 0) { $status = 'missing' }

        if ($status -eq 'healthy' -or $status -eq 'running') { return $true }
        if ($status -eq 'exited' -or $status -eq 'dead') { return $false }

        Start-Sleep -Seconds 2
    }

    Write-C64Warn "Timeout ($TimeoutSeconds s) in attesa del container '$Name' (stato: $status)."
    return $false
}
