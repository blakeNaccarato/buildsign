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

# TODO: Make job for https://ofek.dev/pyapp/latest/how-to/#get-pyapp
# TODO: Replace `src` with `src/pyapp` in `build.rs`
# TODO: Add the following to `Cargo.toml`...
# TODO: [[bin]]
# TODO: name = "pyapp"
# TODO: path = "src/pyapp/main.rs"


name := 'hello'

# Build Windows binaries
build \
  $PYAPP_PROJECT_NAME = name \
  $PYAPP_PROJECT_PATH = `"$(Get-ChildItem dist -Filter *.whl)"` \
  app = ('bin/' + name + '.exe') \
  alg = 'SHA256' \
  progx86 = 'C:/Program Files (x86)' \
  pyapp = 'target/release/pyapp.exe' \
:
  uv build
  cargo build --release
  git restore 'Cargo.lock'
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
    '/dlib' {{ quote(env('USERPROFILE') + '/.nuget/packages/microsoft.trusted.signing.client/1.0.60/bin/x64/Azure.CodeSigning.Dlib.dll') }} \
    '{{app}}'
