<#.SYNOPSIS
Install script.#>

# ? Get the script contents
$Title = 'hello'
$Script = "$Title.py"
$Icon = "$Title.ico"
if ($Env:DEV) {
    $ScriptContents = (Get-Content "$PSScriptRoot/$Script")
}
else {
    $Hub = 'https://raw.githubusercontent.com'
    $User = 'blakeNaccarato'
    $Repo = 'script'
    $Hash = '6f964c50b67fb049ac60c3f4b2cd0fb1b3c05602'
    $Url = "$Hub/$User/$Repo/$Hash"
    $ScriptContents = Invoke-RestMethod "$Url/$Script"
    $IconPath = "$Env:APPDATA/$Title-$($Hash.Substring(0,7))/$Icon"
    Invoke-RestMethod "$Url/$Icon" -OutFile $IconPath
}

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
    powershell -Command "Invoke-RestMethod 'https://astral.sh/uv/install.ps1' | Invoke-Expression"
}

# ? Define script invocation and display help
function Invoke-Script {
    <#.SYNOPSIS
    Invoke script.#>
    [CmdletBinding(PositionalBinding = $False)]
    Param([Parameter(ValueFromPipeline, ValueFromRemainingArguments)][string[]]$Run)
    Process { $ScriptContents | uv run --script - $Run }
}
Invoke-Script --help
