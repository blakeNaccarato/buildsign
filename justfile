set shell := ['pwsh', '-Command']
set dotenv-load
sync := './Sync-Environment; '
dev := sync + 'uv run '
sync:
  {{sync}}
pre-commit *flags :
  {{dev}} pre-commit run --verbose {{flags}}
pyright:
  {{dev}} pyright
pytest:
  {{dev}} pytest
ruff:
  {{dev}} ruff check .
