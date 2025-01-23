set shell := ['pwsh', '-Command']
set dotenv-load
dev := './Sync-Environment; uv run '
sync:
  {{dev}}
pre-commit:
  {{dev}} pre-commit run --verbose
pyright:
  {{dev}} pyright
pytest:
  {{dev}} pytest
ruff:
  {{dev}} ruff check .
