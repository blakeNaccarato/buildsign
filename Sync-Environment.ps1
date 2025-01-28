<#.SYNOPSIS
Sync Python environment based on a script's PEP 723 inline metadata.#>
Param( [string]$Title )

$Pattern = '(?s)# /// script.*?# ///'
$Token = '^# ///'

# ? Error-handling
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $True
$ErrorView = 'NormalView'

# ? Fix leaky UTF-8 encoding settings on Windows
if ($IsWindows) {
    # ? Now PowerShell pipes will be UTF-8. Note that fixing it from Control Panel and
    # ? system-wide has buggy downsides.
    # ? See: https://github.com/PowerShell/PowerShell/issues/7233#issuecomment-640243647
    [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
}

uv sync
if ($IsWindows) { .venv/scripts/activate.ps1 } else { .venv/bin/activate.ps1 }
