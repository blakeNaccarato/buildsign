set shell := ['pwsh', '-NonInteractive', '-NoProfile', '-Command']
set dotenv-load

title := 'hello'

sync := './Sync-Environment -Title ' + title + ' ; '
dev := sync + 'uv run '
sync:
  {{sync}}

build:
  iexpress /N '{{title}}.SED'
execute:
  Start-Process -UseNewEnvironment './{{title}}.exe'

pre-commit *flags :
  uv run pre-commit run --verbose {{flags}}
pyright:
  {{dev}} pyright
pytest:
  {{dev}} pytest
ruff:
  {{dev}} ruff check .
