. ./scripts/pre.ps1
uvx --from "rust-just@$(Get-Content '.just-version')" just --explain @Args
