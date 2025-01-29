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
pre-commit *flags :
  {{run}} pre-commit run --verbose {{flags}}

# Build Windows binaries
build \
  $PYAPP_PROJECT_NAME = name \
  $PYAPP_PROJECT_PATH = `"$(Get-ChildItem dist -Filter *.whl)"` \
  : && sign
    uv build
    cargo install --force 'pyapp' --root '.'
    & {{hacker}} \
      -Open {{pyapp}} \
      -Save {{app}} \
      -Action 'addoverwrite' \
      -Res '{{name}}.ico' \
      -Mask 'ICONGROUP,MAINICON'
app := 'bin/' + name + '.exe'
hacker := quote(progx86 + '/Resource Hacker/ResourceHacker.exe')
name := 'hello'
progx86 := 'C:/Program Files (x86)'
pyapp := 'bin/pyapp.exe'

# Sign Windows binaries
[script]
sign:
  {{pre}}
  $Sign = @(
      'sign'
      '/v'                                         # Verbose output
      '/debug'                                     # Display debugging information
      '/fd', '{{alg}}'                             # File digest algorithm
      '/td', '{{alg}}'                             # Timestamp digest algorithm
      '/tr', 'http://timestamp.acs.microsoft.com'  # Timestamp server
      '/dmdf', 'signing.json'                      # Metadata file
      '/dlib', {{ quote(env('USERPROFILE') + '/.nuget/packages/microsoft.trusted.signing.client/1.0.60/bin/x64/Azure.CodeSigning.Dlib.dll') }}
      '{{app}}'
  )
  & {{signtool}} @Sign
  Remove-Item {{pyapp}}
alg := 'SHA256'
signtool := quote(progx86 + '/Windows Kits/10/bin/10.0.26100.0/x64/signtool.exe')
