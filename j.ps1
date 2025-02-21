<#.SYNOPSIS
Run recipes.#>
[CmdletBinding()]
Param([Parameter(ValueFromRemainingArguments)][string[]]$RemainingArgs)

#? Source common shell config
. ./scripts/pre.ps1
#? Set verbosity and CI-specific environment variables
$Verbose = $Env:CI -or ($DebugPreference -ne 'SilentlyContinue') -or ($VerbosePreference -ne 'SilentlyContinue')
$Env:DEV_VERBOSE = $Verbose ? 'true' : $null
$Env:JUST_VERBOSE = $Verbose ? '1' : $null
#? Set environment variables
$Env:DEV_ENV = ''
@{
    #? Flag we can check later to see if the environment has been set
    DEV_ENV_SET                    = '1'
    #? Other environment variables
    BUILDSIGN_VERSION              = '0.0.0'
    COVERAGE_CORE                  = 'sysmon'
    JUPYTER_PLATFORM_DIRS          = '1'
    JUST_COLOR                     = $Env:CI ? 'always' : $null
    JUST_COMMAND_COLOR             = 'purple'
    JUST_EXPLAIN                   = 'true'
    JUST_LIST_SUBMODULES           = 'true'
    JUST_NO_DOTENV                 = $Env:CI ? 'true' : $null
    JUST_TIMESTAMP                 = $Env:CI ? 'true' : $null
    JUST_UNSORTED                  = 'true'
    JUST_VERSION                   = '1.39.0'
    PYAPP_VERSION                  = '0.26.0'
    PYDEVD_DISABLE_FILE_VALIDATION = '1'
    PYRIGHT_PYTHON_PYLANCE_VERSION = '2025.2.1'
    PYTHON_VERSION                 = '3.12'
    PYTHONIOENCODING               = 'utf-8:strict'
    PYTHONUTF8                     = '1'
    PYTHONWARNDEFAULTENCODING      = '1'
    PYTHONWARNINGS                 = 'ignore'
    UV_PREVIEW                     = '1'
    UV_VERSION                     = '0.5.29'
}.GetEnumerator() | Sort-Object Key | ForEach-Object {
    $K, $V = $_.Key, $_.Value
    if ($V) {
        Set-Item "Env:$K" $V
        $Env:DEV_ENV += "$K=$V;"
    }
}
$Env:DEV_ENV = $Env:DEV_ENV.TrimEnd(';')
#? Pass arguments to Just
if ($RemainingArgs) { uvx --from "rust-just@$Env:JUST_VERSION" just @RemainingArgs }
else { uvx --from "rust-just@$Env:JUST_VERSION" just list }
