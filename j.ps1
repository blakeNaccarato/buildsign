<#.SYNOPSIS
Run recipes.#>
[CmdletBinding()]
Param([Parameter(ValueFromRemainingArguments)][string[]]$Args)

#? Source common shell config
. ./scripts/pre.ps1
#? Set environment variables
$Env:DEV_ENV = ''
@{
    #? Flag we can check later to see if the environment has been set
    DEV_ENV_SET                    = '1'
    #? Other environment variables
    BUILDSIGN_VERSION              = '0.0.0'
    COVERAGE_CORE                  = 'sysmon'
    JUPYTER_PLATFORM_DIRS          = '1'
    JUST_COMMAND_COLOR             = 'purple'
    JUST_LIST_SUBMODULES           = 'true'
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
if ($Args) {
    $Verbose = ($VerbosePreference -ne 'SilentlyContinue')
    $Debug = $Env:CI -or ($DebugPreference -ne 'SilentlyContinue')
    $Env:DEV_VERBOSE = $Verbose ? 'true' : $null
    $Env:DEV_DEBUG = $Debug ? 'true' : $null
    $Env:JUST_EXPLAIN = ($Verbose -or $Debug) ? 'true' : $null
    $Env:JUST_QUIET = $Debug ?  $null : 'true'
    uvx --from "rust-just@$Env:JUST_VERSION" just @Args
}
else {
    $Env:DEV_VERBOSE = $Env:DEV_DEBUG = $Env:JUST_EXPLAIN = 'true'
    $Env:JUST_QUIET = $null
    uvx --from "rust-just@$Env:JUST_VERSION" just list
}
