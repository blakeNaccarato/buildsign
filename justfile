set shell := ['pwsh', '-NonInteractive', '-NoProfile', '-Command']
set dotenv-load

title := 'hello'

build:
  iexpress /N '{{title}}.SED'
execute:
  Start-Process -UseNewEnvironment './{{title}}.exe'

sync := './Sync-Environment -Title ' + title + ' ; '
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
