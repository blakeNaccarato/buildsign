<#.SYNOPSIS
Install script.#>
Param( [string]$Title='hello' )

# ? Set the prompt
Set-Item -Path 'Function:/prompt' -Value { '> ' }

# ? Set window title
$Host.UI.RawUI.WindowTitle = $Title

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

# ? Set aliases
@{
    $Title = 'Invoke-Script'
}.GetEnumerator() | ForEach-Object { Set-Alias -Name $_.Key -Value $_.Value }

# ? Add `uv` to path and install it if missing
$Env:PATH = "$HOME/.cargo/bin$([System.IO.Path]::PathSeparator)$Env:PATH"
if (!(Get-Command 'uv' -ErrorAction 'Ignore')) {
    if ($IsWindows) { Invoke-RestMethod 'https://astral.sh/uv/install.ps1' | Invoke-Expression }
    else { curl --proto '=https' --tlsv1.2 -LsSf 'https://astral.sh/uv/install.sh' | sh }
}

# ? Define script invocation and display help
function Invoke-Script {
    <#.SYNOPSIS
    Invoke script.#>
    [CmdletBinding(PositionalBinding = $False)]
    Param([Parameter(ValueFromPipeline, ValueFromRemainingArguments)][string[]]$Run)
    Process { uv run --script "$Title.py" $Run }
}
Invoke-Script --help
