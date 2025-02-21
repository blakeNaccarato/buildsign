Set-StrictMode -Version '3.0'
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $True
$ErrorView = 'NormalView'
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Sync-ContribEnv {
    <#.SYNOPSIS
    Write environment variables to VSCode contributor environment.#>
    $DevEnvJson = ''
    $Env:DEV_ENV -Split ';' | Select-String -Pattern '([^=]+)=([^=]+)' | ForEach-Object {
        $K, $V = $_.Matches.Groups[1].Value, $_.Matches.Groups[2].Value
        $DevEnvJson += "`n    `"$K`": `"$V`","
    }
    $DevEnvJson = "{$($DevEnvJson.TrimEnd(','))`n  }"
    $Settings = '.vscode/settings.json'
    $SettingsContent = Get-Content $Settings -Raw
    foreach ($Plat in ('linux', 'osx', 'windows')) {
        $Pat = "(?m)`"terminal\.integrated\.env\.$Plat`"\s*:\s*\{[^}]*\}"
        $Repl = "`"terminal.integrated.env.$Plat`": $DevEnvJson"
        $SettingsContent = $SettingsContent -Replace $Pat, $Repl
    }
    Set-Content $Settings $SettingsContent -NoNewline
}

function Sync-CiEnv {
    <#.SYNOPSIS
    Sync CI environment path and environment variables.#>
    #? Add `.venv` tools to CI path. Needed for some GitHub Actions like pyright
    $GitHubPath = $Env:GITHUB_PATH ? $Env:GITHUB_PATH : '.dummy-ci-path-file'
    if (!(Test-Path $GitHubPath)) { New-Item $GitHubPath }
    if (!(Get-Content $GitHubPath | Select-String -Pattern '.venv')) {
        Add-Content $GitHubPath ('$.venv/bin', '.venv/scripts')
    }
    #? Write environment variables to CI environment file
    $EnvFile = $Env:GITHUB_ENV ? $Env:GITHUB_ENV : '.dummy-ci-env-file'
    if (!(Test-Path $EnvFile)) { New-Item $EnvFile }
    if (!(Get-Content $EnvFile | Select-String -Pattern 'DEV_ENV_SET')) {
        $Env:DEV_ENV -Split ';' | Add-Content $EnvFile
    }
}
