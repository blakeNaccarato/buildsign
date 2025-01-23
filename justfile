set shell := ['pwsh', '-Command']
set dotenv-load
sync := './Sync-Environment'
dev := sync + '; uv run '
sync:
  {{sync}}
pre-commit:
  {{dev}} pre-commit run --verbose
pyright:
  {{dev}} pyright
pytest:
  {{dev}} pytest
ruff:
  {{dev}} ruff check .
