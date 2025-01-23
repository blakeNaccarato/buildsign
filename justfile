set shell := ['pwsh', '-Command']
set dotenv-load
dev := './Sync-Environment; '
sync:
  {{dev}}
pre-commit: sync
  pre-commit run --verbose
