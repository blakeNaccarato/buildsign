<#.SYNOPSIS
Synchronize Python development environment based on a script's PEP 723 inline metadata.#>
Param([string]$Script = 'script')
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

$PyProject = (Get-Content -Encoding 'UTF8' -Raw 'pyproject.toml').TrimEnd("`n")
$ScriptBlock = Get-Content -Encoding 'UTF8' -Raw "$Script.py" |
    Select-String -Pattern $Pattern
Set-Content -Encoding 'UTF8' 'pyproject.toml' (
    $PyProject -Replace $Pattern, (
        (
            $ScriptBlock.Matches.Value -Split "`n" |
                ForEach-Object {
                    if ($_ -NotMatch $Token) { $_ -Replace '^# ', '' } else { $_ }
                }
        ) -Join "`n"
    )
)
uv sync
git add 'pyproject.toml'
