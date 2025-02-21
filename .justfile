#* Project
name :=\
  'buildsign'
python_version :=\
  env('PYTHON_VERSION', empty)
uv_version :=\
  env('UV_VERSION', empty)

#* Settings
set dotenv-load
set unstable

#* Imports
import 'scripts/common.just'

#* Modules
#? 🌐 Install
mod inst 'scripts/inst.just'

#* Shells
set shell :=\
  ['pwsh', '-NonInteractive', '-NoProfile', '-CommandWithArgs']
set script-interpreter :=\
  ['pwsh', '-NonInteractive', '-NoProfile']

#* Reusable shell preambles
pre :=\
  pwsh_pre + ';'
script_pre :=\
  pwsh_pre

#* ♾️  Self

#? Also the default recipe, as it is the first recipe in the file
# 📃 List recipes.
[group('♾️  Self')]
list:
  {{pre}} {{_just}} --list

# #* ⛰️ Environments

# 🏃 Run shell command with UV synced.
[group('⛰️ Environments')]
run *args="Write-Host 'No command given' -ForeGroundColor Yellow": uv-update uv-sync
  {{ pre + sp + args }}
alias r := run

# 👥 Run recipe as a contributor.
[script, group('⛰️ Environments')]
@con *args: uv-update con-pre-commit-hooks uv-sync
  {{'#?'+BLUE+sp+'Source common shell config'+NORMAL}}
  {{script_pre}}
  {{'#?'+BLUE+sp+'Write environment variables to VSCode contributor environment'+NORMAL}}
  $DevEnvJson = ''
  $Env:DEV_ENV -Split ';' | Select-String -Pattern '([^=]+)=([^=]+)' | ForEach-Object {
    $K, $V = $_.Matches.Groups[1].Value, $_.Matches.Groups[2].Value
    $DevEnvJson += "`n    `"$K`": `"$V`","
  }
  $DevEnvJson = "{$($DevEnvJson.TrimEnd(','))`n  }"
  $Settings = '.vscode/settings.json'
  $SettingsContent = Get-Content $Settings -Raw
  foreach ($Plat in ('linux', 'osx', 'windows')) {
    $Pat = "(?m)`"terminal\.integrated\.env\.$Plat`"\s*:\s*\{[^}]*\}"
    $Repl = "`"terminal.integrated.env.$Plat`": $DevEnvJson"
    $SettingsContent = $SettingsContent -Replace $Pat, $Repl
  }
  Set-Content $Settings $SettingsContent -NoNewline
  {{'#?'+BLUE+sp+'Run recipe'+NORMAL}}
  {{ if args==empty { empty } else { _just + sp + args } }}
alias c := con

# 🤖 Run recipes in CI.
[script, group('⛰️ Environments')]
@ci *args: uv-sync
  {{'#?'+BLUE+sp+'Source common shell config'+NORMAL}}
  {{script_pre}}
  {{'#?'+BLUE+sp+'Add `.venv` tools to CI path. Needed for some GitHub Actions like pyright.'+NORMAL}}
  $GitHubPath = $Env:GITHUB_PATH ? $Env:GITHUB_PATH : '.dummy-ci-path-file'
  if (!(Test-Path $GitHubPath)) { New-Item $GitHubPath }
  if ( !(Get-Content $GitHubPath | Select-String -Pattern ".venv") ) {
    Add-Content $GitHubPath (".venv/bin", ".venv/scripts")
  }
  {{'#?'+BLUE+sp+'Write environment variables to CI environment file'+NORMAL}}
  $EnvFile = $Env:GITHUB_ENV ? $Env:GITHUB_ENV : '.dummy-ci-env-file'
  if (!(Test-Path $EnvFile)) { New-Item $EnvFile }
  if (!(Get-Content $EnvFile | Select-String -Pattern 'DEV_ENV_SET')) {
    $Env:DEV_ENV -Split ';' | Add-Content $EnvFile
  }
  {{'#?'+BLUE+sp+'Elevate Pyright warnings to errors in CI'+NORMAL}}
  {{_dev}} elevate-pyright-warnings
  {{'#?'+BLUE+sp+'Run recipe'+NORMAL}}
  {{ if args==empty { empty } else { _just + sp + args } }}

# 📦 Run recipes in a devcontainer.
[script, group('⛰️ Environments')]
@devcontainer *args:
  {{'#?'+BLUE+sp+'Source common shell config'+NORMAL}}
  {{script_pre}}
  {{'#?'+BLUE+sp+'Devcontainers need submodules explicitly marked as safe directories'+NORMAL}}
  $Repo = Get-ChildItem '/workspaces'
  $Packages = Get-ChildItem "$Repo/packages"
  $SafeDirs = @($Repo) + $Packages
  foreach ($Dir in $SafeDirs) {
    if (!($SafeDirs -contains $Dir)) { git config --global --add safe.directory $Dir }
  }
  {{'#?'+BLUE+sp+'Run recipe'+NORMAL}}
  {{ if args==empty { empty } else { _just + sp + args } }}
alias dc := devcontainer

#* 🟣 uv

#? Uv invocations
_uv_options :=\
  '--all-packages' \
  + sp + '--python' + ( \
    if python_version==empty { empty } else { sp + quote(python_version) } \
  )
_uv :=\
  'uv'
_uvr :=\
  _uv + sp + 'run' + sp + _uv_options
_uvs :=\
  _uv + sp + 'sync' + sp + _uv_options

# 🟣 uv
[group('🟣 uv')]
uv *args:
  {{pre}} {{_uv}} {{args}}

# 🏃 uv run ...
[group('🟣 uv')]
uv-run *args:
  {{pre}} {{_uvr}} {{args}}
alias uvr := uv-run

# 🌐 Synchronize installed uv version with project uv version.
[group('🟣 uv')]
uv-update:
  uv self update{{ if uv_version==empty { empty } else { sp + quote(uv_version) } }}

# ♻️ uv sync ...
[group('🟣 uv')]
uv-sync *args:
  {{pre}} {{_uvs}} {{args}}
alias uvs := uv-sync
alias sync := uv-sync

#* 🐍 Python

# 🐍 python ...
[group('🐍 Python')]
py *args:
  {{pre}} {{_uvr}} 'python' {{args}}
alias py- := py

# 📄 uv run --script ...
[group('🐍 Python')]
py-script script *args:
  {{pre}} {{_uvr}} '--script' {{quote(script)}} {{args}}
alias pys := py-script

# 📺 uv run --gui-script ...
[windows, group('🐍 Python')]
py-gui-script script *args:
  {{pre}} {{_uvr}} '--gui-script' {{quote(script)}} {{args}}
alias pyg := py-gui-script
# ❌ uv run --gui-script ...
[linux, macos, group('❌ N/A for this OS')]
py-gui-script:
  @{{quote(GREEN+'GUI scripts'+sp+_na+NORMAL)}}


# 📦 uv run --module ...
[group('🐍 Python')]
py-module module *args:
  {{pre}} {{_uvr}} '--module' {{quote(module)}} {{args}}
alias pym := py-module

# 🏃 uv run python -c '...'
[group('🐍 Python')]
py-command cmd:
  {{pre}} {{_uvr}} 'python' '-c' {{quote(cmd)}}
alias pyc := py-command

#* ⚙️ Tools

# ✔️  pre-commit run ...
[group('⚙️  Tools')]
tool-pre-commit *args: con
  {{pre}} {{_uvr}} pre-commit run --verbose {{args}}
alias pre-commit := tool-pre-commit
alias pc := tool-pre-commit

# ✔️  pre-commit run --all-files ...
[group('⚙️  Tools')]
tool-pre-commit-all *args:
  {{pre}} {{_just}} pre-commit --all-files {{args}}
alias pre-commit-all := tool-pre-commit-all
alias pca := tool-pre-commit-all

# ✔️  fawltydeps ...
[group('⚙️  Tools')]
tool-fawltydeps *args:
  {{pre}} {{_uvr}} fawltydeps {{args}}
alias fawltydeps := tool-fawltydeps

# ✔️  pyright
[group('⚙️  Tools')]
tool-pyright:
  {{pre}} {{_uvr}} pyright
alias pyright := tool-pyright

# ✔️  ruff check <args> '.'
[group('⚙️  Tools')]
tool-ruff *args:
  {{pre}} {{_uvr}} ruff check {{args}} .
alias ruff := tool-ruff

# 🧪 pytest
[group('⚙️  Tools')]
tool-pytest *args:
  {{pre}} {{_uvr}} pytest {{args}}
alias pytest := tool-pytest

# 📖 docs
[group('⚙️  Tools')]
tool-docs-preview:
  {{pre}} {{_uvr}} sphinx-autobuild --show-traceback docs _site \
    {{ prepend( '--ignore', "'**/temp' '**/data' '**/apidocs' '**/*schema.json'" ) }}

# 📖 docs
[group('⚙️  Tools')]
tool-docs-build:
  {{pre}} {{_uvr}} sphinx-build 'docs' '_site'

#* 📦 Packaging

# 🛞  Build wheel, compile binary, and sign.
[group('📦 Packaging')]
pkg-build *args:
  {{pre}} {{_uvr}} {{name}} {{args}}
alias build := pkg-build

# ✨ Release new version.
[group('📦 Packaging')]
pkg-release version:
  {{pre}} git tag --sign -m {{quote(version)}} {{quote(version)}} && git push
alias release := pkg-release

#* 👥 Contributor environment setup

_dev :=\
  _uvr + sp + quote(name + '-dev')

# 👥 Update Git submodules.
[group('👥 Contributor environment setup')]
con-git-submodules:
  {{pre}} Get-ChildItem '.git/modules' -Filter 'config.lock' -Recurse -Depth 1 | \
      Remove-Item
  {{pre}} git submodule update --init --merge

# 👥 Install pre-commit hooks.
[script, group('👥 Contributor environment setup')]
@con-pre-commit-hooks:
  {{'#?'+BLUE+sp+'Source common shell config'+NORMAL}}
  {{script_pre}}
  {{'#?'+BLUE+sp+'Install hooks if missing'+NORMAL}}
  if (
    ({{quote(hooks)}} -Split {{quote(sp)}} |
      ForEach-Object { ".git/hooks/$_" } |
      Test-Path
    ) -Contains $False
  ) {
    {{_uvr}} pre-commit install --install-hooks | Out-Null
    {{ quote(GREEN + 'Pre-commit hooks installed.' + NORMAL) }}
  }
hooks :=\
  'pre-commit'

# 👥 Normalize line endings.
[script, group('👥 Contributor environment setup')]
@con-norm-line-endings:
  {{'#?'+BLUE+sp+'Source common shell config'+NORMAL}}
  {{script_pre}}
  {{'#?'+BLUE+sp+'Normalize line endings'+NORMAL}}
  try { {{_uvr}} pre-commit run mixed-line-ending --all-files | Out-Null }
  catch [System.Management.Automation.NativeCommandExitException] {}

# 👥 Run dev task.
[group('👥 Contributor environment setup')]
con-dev *args:
  {{pre}} {{_dev}} {{args}}
alias dev := con-dev

#* 💻 Machine setup

# 🔓 Allow running local PowerShell scripts.
[windows, group('💻 Machine setup')]
setup-scripts:
  {{pre}} Set-ExecutionPolicy -Scope 'CurrentUser' 'RemoteSigned'

# 👤 Set Git username and email.
[group('💻 Machine setup')]
setup-git username email:
  {{pre}} git config --global user.name {{quote(username)}}
  {{pre}} git config --global user.email {{quote(email)}}

# 👤 Configure Git as recommended.
[group('💻 Machine setup')]
setup-git-recs:
  {{pre}} git config --global fetch.prune true
  {{pre}} git config --global pull.rebase true
  {{pre}} git config --global push.autoSetupRemote true
  {{pre}} git config --global push.followTags true

# 🔑 Log in to GitHub API.
[group('💻 Machine setup')]
setup-gh:
  {{pre}} gh auth login
