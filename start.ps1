#Requires -Version 5.1
# Convenience wrapper -> scripts\start.ps1
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'scripts\start.ps1') @args
