Param([string]$Directory='')
Set-StrictMode -Version '3.0'
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $True
$ErrorView = 'NormalView'
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.Encoding]::UTF8
if ($Directory) { Set-Location $Directory }
