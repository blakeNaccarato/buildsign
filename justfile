set shell := ['pwsh', '-NonInteractive', '-NoProfile', '-Command']
set dotenv-load

name := 'hello'

sync := 'scripts/Sync-Environment; '
dev := sync + 'uv run '
sync:
  {{sync}}
build:
  uv build --resolution 'lowest-direct'
  $Env:PYAPP_PROJECT_NAME='{{name}}'; $Env:PYAPP_PROJECT_PATH=(Get-ChildItem 'dist' -Filter '*.whl'); cargo install --force 'pyapp' --root '.'
  & 'C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe' -open "bin/pyapp.exe" -save "bin/{{name}}.exe" -action addoverwrite -res "hello.ico" -mask ICONGROUP,MAINICON
  Remove-Item 'bin/pyapp.exe'
  scripts/Sign-Binaries.ps1

pre-commit *flags :
  uv run pre-commit run --verbose {{flags}}
pyright:
  {{dev}} pyright
pytest:
  {{dev}} pytest
ruff:
  {{dev}} ruff check .
