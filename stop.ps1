#Requires -Version 5.1
# Convenience wrapper -> scripts\stop.ps1
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'scripts\stop.ps1') @args
