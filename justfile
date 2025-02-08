#? Settings
set dotenv-load
set unstable

#? Shells
set windows-shell := ['powershell.exe', '-NonInteractive', '-NoProfile', '-Command']
set shell := ['bash', '--noprofile', '--norc', '--posix', '-c']

#? Reusable shell preambles
preamble := '. scripts/preamble' + (if os_family()=='windows' { '.ps1' } else {'.sh'})
preamble_cd := preamble + ' ' + invocation_dir()

#? Basic commands

run cmd:
  {{preamble}}; {{cmd}}
uv *args:
  {{preamble}}; uv {{args}}
uvr *args:
  {{preamble}}; {{_uvr}} {{args}}
_uvr := 'uv run'

#? Common tasks

pyright:
  {{_uvr}} pyright
pytest:
  {{_uvr}} pytest
ruff:
  {{_uvr}} ruff check .
pre-commit *args:
  {{_uvr}} pre-commit run --verbose {{args}}

#? Build

#* Tool versions
pyapp_version := trim(read('.pyapp-version'))
python_version := trim(read('.python-version'))
uv_version := trim(read('.uv-version'))

#* Project details
proj_name := 'hello'
proj_version := '0.0.0'
proj_icon := if path_exists(absolute_path( invocation_dir()/_icon )) == 'true' \
  {absolute_path( invocation_dir()/_icon )} \
  else {absolute_path( invocation_dir()/_default_icon )}
_icon := proj_name + '.ico'
_default_icon := 'default.ico'

#* Tools
zip := if os_family()=='windows' {require( '7z.exe' )} else {require( 'tar' )}
rcedit := require('rcedit' + _ext)
jsign := require('jsign' + _ext)
_ext := (if os_family()=='windows' { '.exe' } else {''})

#* Artifacts
wheel := absolute_path( invocation_dir()/'dist'/proj_name+'-'+proj_version+'-py3-none-any.whl' )
pyapp := absolute_path( justfile_dir()/'pyapp' )
pyapp_bin := absolute_path( pyapp/'target/release/pyapp.exe' )
cargo_lock := absolute_path( pyapp/'Cargo.lock' )
bin := absolute_path( invocation_dir()/'dist'/(proj_name+'.exe') )

#* Recipes

# Build wheel, compile binary, change its icon, and sign it
build: _build _compile _change_icon _sign

# Build wheel
_build:
  {{preamble_cd}}; uv build --package '{{proj_name}}'

#? Get PyApp sources
# TODO: Implement bash version as well
__get_pyapp_sources := \
  preamble + '; ' \
  + "Invoke-WebRequest" \
  + " 'https://github.com/ofek/pyapp/releases/download/v" + pyapp_version + "/source.zip'" \
  + " -OutFile 'source.zip'; " \
  + zip + " 'x' 'source.zip'; " \
  + "mv 'pyapp-v*' 'pyapp'; " \
  + 'git restore' + absolute_path( pyapp/".cargo/config.toml" ) + '; ' \
  + "git add '" + cargo_lock + "'; " \
  + "rm 'source.zip'"
# Get PyApp sources
_get_pyapp_sources:
  {{ if path_exists(pyapp) == 'true' { "" } else { __get_pyapp_sources } }}

# Compile binary
_compile \
  $PYAPP_EXPOSE_ALL_COMMANDS = '1' \
  $PYAPP_PYTHON_VERSION = python_version \
  $PYAPP_PROJECT_NAME = proj_name \
  $PYAPP_UV_ENABLED = '1' \
  $PYAPP_UV_VERSION = uv_version \
  $PYAPP_PROJECT_PATH = wheel \
: _get_pyapp_sources
  {{preamble}} '{{pyapp}}'; cargo build --release
  git restore '{{cargo_lock}}'
  {{ if path_exists(bin) == "true" { "rm " + bin } else {""} }}
  mv '{{pyapp_bin}}' '{{bin}}'

# Change icon
_change_icon:
  {{preamble}}; {{rcedit}} '{{bin}}' --set-icon '{{proj_icon}}'

# Sign binary
_sign account='blake-naccarato' profile='blake-naccarato':
  {{preamble_cd}}; {{jsign}} \
    --storetype 'TRUSTEDSIGNING' \
    --keystore 'wus3.codesigning.azure.net' \
    --alias '{{account}}/{{profile}}' \
    --storepass (az account get-access-token \
      --resource 'https://codesigning.azure.net' \
      --query 'accessToken' \
    ) \
    '{{bin}}'
