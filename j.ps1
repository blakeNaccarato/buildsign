. ./scripts/pre.ps1
$Env:JUST_COMMAND_COLOR = 'purple'
$Env:JUST_EXPLAIN = 'true'
$Env:UV_PREVIEW = '1'
$Env:UVX_JUST = "rust-just@$JustVersion"
$JustVersion = $Env:JUST_VERSION ? $Env:JUST_VERSION : '1.39.0'
uvx --from "rust-just@$JustVersion" just @Args
