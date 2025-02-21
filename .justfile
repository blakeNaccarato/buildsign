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
  ['pwsh', '-NonInteractive', '-NoProfile', '-Command']
set script-interpreter :=\
  ['pwsh', '-NonInteractive', '-NoProfile']

#* Reusable shell preambles
pre :=\
  pwsh_pre

#* ♾️  Self

#? Also the default recipe, as it is the first recipe in the file
# 📃 List recipes.
[group('♾️  Self')]
list:
  {{pre}} {{_just}} --list --unsorted --list-submodules

#* 🏃 Run

# 🏃 Run any shell command.
[group('🏃 run')]
run *args:
  {{pre}} {{args}}
alias r := run

#* 🟣 uv

#? Uv invocations
python_version :=\
  env('PYTHON_VERSION', '3.12')
_uv_options :=\
  '--all-packages' \
  + sp + '--python' + sp + quote(python_version)
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
  uv self update {{env('UV_VERSION')}}

# ♻️ uv sync ...
[group('🟣 uv')]
uv-sync *args:
  {{pre}} {{_uvs}} {{args}}
alias uvs := uv-sync

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
tool-pre-commit *args:
  {{pre}} {{_just_silent}} contrib-setup
  {{pre}} {{_just}} {{_uvr}} pre-commit run --verbose {{args}}
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
  {{pre}} {{_uvr}} -EaT 'docs' '_site'

#* 📦 Packaging

# 🛞  Build wheel, compile binary, and sign.
[group('📦 Packaging')]
pkg-build *args:
  {{pre}} {{_uvr}} buildsign {{args}}
alias build := pkg-build

# ✨ Release new version.
[group('📦 Packaging')]
pkg-release version:
  {{pre}} git tag --sign -m {{quote(version)}} {{quote(version)}} && git push
alias release := pkg-release

#* 👥 Contributor environment setup

_contrib_dev :=\
  if path_exists('.venv')==true { _uvr + sp + _dev } \
  else { 'uvx --with-editable' + sp + quote('./packages/_dev') + sp + _dev }
_dev :=\
  'buildsign-dev'

# 👥 Set up contributor environment.
[group('👥 Contributor environment setup')]
contrib-setup: \
  contrib-sync-environment-variables \
  contrib-pre-commit-hooks
    {{pre}} {{_just}} uv-update
    {{pre}} {{_just}} \
      contrib-git-submodules \
      contrib-norm-line-endings \
      contrib-pre-commit-hooks \
      uv-sync

# 👥 Update Git submodules.
[group('👥 Contributor environment setup')]
contrib-git-submodules:
  {{pre}} Get-ChildItem '.git/modules' -Filter 'config.lock' -Recurse -Depth 1 | \
      Remove-Item
  {{pre}} git submodule update --init --merge

# 👥 Install pre-commit hooks.
[script, group('👥 Contributor environment setup')]
@contrib-pre-commit-hooks:
  {{pre}}
  if (
    ({{quote(hooks)}} -Split {{quote(sp)}} |
      ForEach-Object { ".git/hooks/$_" } |
      Test-Path
    ) -Contains $False
  ) { {{_uvr}} pre-commit install --install-hooks | Out-Null }
  else { {{quote(GREEN+'Pre-commit hooks already installed.'+NORMAL)}} }
hooks :=\
  'pre-commit'

# 👥 Normalize line endings.
[script, group('👥 Contributor environment setup')]
@contrib-norm-line-endings:
  {{pre}}
  try { {{_uvr}} pre-commit run mixed-line-ending --all-files | Out-Null }
  catch [System.Management.Automation.NativeCommandExitException] {}

# 👥 Run dev task.
[group('👥 Contributor environment setup')]
contrib-dev *args:
  {{pre}} _contrib_dev {{args}}
alias dev := contrib-dev

# 👥 Sync environment variables.
[script, group('👥 Contributor environment setup')]
@contrib-sync-environment-variables:
  {{pre}}
  #? Sync `.env` and set environment variables from `pyproject.toml`
  $EnvFile = '.env'
  if (!(Test-Path $EnvFile)) { New-Item $EnvFile }
  $EnvVars = {{_contrib_dev}} sync-environment-variables
  $EnvVars | Set-Content ($Env:GITHUB_ENV ? $Env:GITHUB_ENV : $EnvFile)
  $EnvVars | Select-String -Pattern '^(.+?)=(.+)$' | ForEach-Object {
    $K, $V = $_.Matches.Groups[1].Value, $_.Matches.Groups[2].Value
    Set-Item "Env:$K" $V
  }
  #? Sync `.vscode/settings.json` with environment variables
  $ProjEnvJson = '{'
  ({{_contrib_dev}} sync-environment-variables --config-only) |
    Select-String -Pattern '^(.+?)=(.+)$' |
    ForEach-Object {
      $K, $V = $_.Matches.Groups[1].Value, $_.Matches.Groups[2].Value
      $ProjEnvJson += "`n    `"$K`": `"$V`","
    }
  $ProjEnvJson = "$($ProjEnvJson.TrimEnd(','))`n  }"
  $Settings = '.vscode/settings.json'
  $SettingsContent = Get-Content $Settings -Raw
  foreach ($Plat in ('linux', 'osx', 'windows')) {
    $Pat = "(?m)`"terminal\.integrated\.env\.$Plat`"\s*:\s*\{[^}]*\}"
    $Repl = "`"terminal.integrated.env.$Plat`": $ProjEnvJson"
    $SettingsContent = $SettingsContent -Replace $Pat, $Repl
  }
  Set-Content $Settings $SettingsContent -NoNewline

#* 💻 Machine setup

# 🔓 Allow running local PowerShell scripts.
[windows, group('💻 Machine setup')]
mach-scripts:
  {{pre}} Set-ExecutionPolicy -Scope 'CurrentUser' 'RemoteSigned'

# 👤 Set Git username and email.
[group('💻 Machine setup')]
mach-git name email:
  {{pre}} git config --global user.name {{quote(name)}}
  {{pre}} git config --global user.email {{quote(email)}}

# 👤 Configure Git as recommended.
[group('💻 Machine setup')]
mach-git-recs:
  {{pre}} git config --global fetch.prune true
  {{pre}} git config --global pull.rebase true
  {{pre}} git config --global push.autoSetupRemote true
  {{pre}} git config --global push.followTags true

# 🔑 Log in to GitHub API.
[group('💻 Machine setup')]
mach-gh:
  {{pre}} gh auth login

# 🤖 Set up CI.
[group('💻 Machine setup')]
mach-ci: contrib-sync-environment-variables
  {{pre}} {{_just}} uv-sync
  {{pre}} Add-Content $Env:GITHUB_PATH ("$PWD/.venv/bin", "$PWD/.venv/scripts")
  {{_contrib_dev}} elevate-pyright-warnings
alias ci := mach-ci

# 📦 Set up devcontainer.
[script, group('💻 Machine setup')]
mach-devcontainer:
  {{pre}}
  $Repo = Get-ChildItem '/workspaces'
  $Packages = Get-ChildItem "$Repo/packages"
  $SafeDirs = @($Repo) + $Packages
  foreach ($Dir in $SafeDirs) {
    if (!($SafeDirs -contains $Dir)) { git config --global --add safe.directory $Dir }
  }
