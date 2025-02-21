. ./scripts/pre.ps1
$Env:JUST_EXPLAIN = 'true'
$Env:JUST_COMMAND_COLOR = 'purple'
uvx --from "rust-just@$(Get-Content '.just-version')" just @Args
