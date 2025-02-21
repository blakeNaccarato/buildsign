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
$EnvVars = Get-Content 'env.json' | ConvertFrom-Json
@{
    JUST_COLOR     = $Env:CI ? 'always' : $null
    JUST_NO_DOTENV = $Env:CI ? 'true' : $null
    JUST_TIMESTAMP = $Env:CI ? 'true' : $null
}.GetEnumerator() | ForEach-Object {
    $K, $V = $_.Key, $_.Value
    if ($V) { $EnvVars | Add-Member -NotePropertyName $K -NotePropertyValue $V }
}
$Env:DEV_ENV = ''
$EnvVars.PsObject.Properties | Sort-Object Name | ForEach-Object {
    $N, $V = $_.Name, $_.Value
    if ($V) {
        Set-Item "Env:$N" $V
        $Env:DEV_ENV += "$N=$V;"
    }
}
$Env:DEV_ENV = $Env:DEV_ENV.TrimEnd(';')
#? Pass arguments to Just
if ($RemainingArgs) { uvx --from "rust-just@$Env:JUST_VERSION" just @RemainingArgs }
else { uvx --from "rust-just@$Env:JUST_VERSION" just list }
