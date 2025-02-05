# Imports
import 'scripts/pre.just'

# Settings
set unstable
set dotenv-load
set shell := ['pwsh', '-NonInteractive', '-NoProfile', '-Command']
set script-interpreter := ['pwsh', '-NonInteractive', '-NoProfile']

run := 'uv run'

pyright:
  {{run}} pyright
pytest:
  {{run}} pytest
ruff:
  {{run}} ruff check .
# Run pre-commit (verbose)
pre-commit *args :
  {{run}} pre-commit run --verbose {{args}}

name := 'hello'

build: && build-exe sign
  uv build

# TODO: Make recipe that gets/unzips pyapp sources into `./pyapp`

# Build Windows binaries
[working-directory: 'pyapp']
build-exe \
  $PYAPP_EXPOSE_ALL_COMMANDS = '1' \
  $PYAPP_PROJECT_NAME = name \
  $PYAPP_PROJECT_PATH = `"$(Get-ChildItem dist -Filter *.whl)"` \
  $PYAPP_PYTHON_VERSION = '3.12' \
  $PYAPP_UV_ENABLED = '1' \
  $PYAPP_UV_VERSION = '0.5.24' \
:
  cargo build --release
  git restore 'Cargo.lock'

# Sign Windows binaries
sign \
  app = ('bin/' + name + '.exe') \
  alg = 'SHA256' \
  dlib_path = '/.nuget/packages/microsoft.trusted.signing.client/1.0.60/bin/x64/Azure.CodeSigning.Dlib.dll' \
  progx86 = 'C:/Program Files (x86)' \
  pyapp = 'pyapp/target/release/pyapp.exe' \
:
  & {{ quote(progx86 + '/Resource Hacker/ResourceHacker.exe') }} \
    -open {{pyapp}} \
    -save {{app}} \
    -action 'addoverwrite' \
    -res '{{name}}.ico' \
    -mask 'ICONGROUP,MAINICON'
  & {{ quote(progx86 + '/Windows Kits/10/bin/10.0.26100.0/x64/signtool.exe') }} \
    'sign' \
    '/v' \
    '/debug' \
    '/fd' '{{alg}}' \
    '/td' '{{alg}}' \
    '/tr' 'http://timestamp.acs.microsoft.com' \
    '/dmdf' 'signing.json' \
    '/dlib' {{ quote(env('USERPROFILE') + dlib_path) }} \
    '{{app}}'
