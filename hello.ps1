<#.SYNOPSIS
Install script.#>

$Title = 'hello'
$Script = "$Title.py"

# ? Fix leaky UTF-8 encoding
[console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# ? Error-handling
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $True
$ErrorView = 'NormalView'

# ? Set the prompt
Set-Item -Path 'Function:/prompt' -Value { '> ' }

# ? Set window title
$Host.UI.RawUI.WindowTitle = $Title

# ? Set aliases
@{
    $Title = 'Invoke-Script'
}.GetEnumerator() | ForEach-Object { Set-Alias -Name $_.Key -Value $_.Value }

# ? Define script invocation and display help
function Invoke-Script {
    [CmdletBinding(PositionalBinding = $False)]
    Param([Parameter(ValueFromPipeline, ValueFromRemainingArguments)][string[]]$Run)
    Process { & "./$Title-pyapp.exe" $Run }
}
Invoke-Script --help
