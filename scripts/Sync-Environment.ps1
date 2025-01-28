<#.SYNOPSIS
Sync and activate Python environment.#>
uv sync
if ($IsWindows) { .venv/scripts/activate.ps1 } else { .venv/bin/activate.ps1 }
