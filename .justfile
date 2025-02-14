#? Load `.env`
set dotenv-load
#? Set shells
set windows-shell := ['powershell.exe', '-NonInteractive', '-NoProfile', '-Command']
set shell := ['bash', '--noprofile', '--norc', '--posix', '-c']
#? Set up reusable shell preambles
p := '. scripts/preamble' + (if os_family()=='windows' { '.ps1' } else {'.sh'})
pcd := p + ' ' + invocation_dir()

#? Basic commands

run cmd:
  {{p}}; {{cmd}}
uv *args:
  {{p}}; uv {{args}}
uvr *args:
  {{p}}; {{_uvr}} {{args}}
py *args:
  {{p}}; {{_uvr}} 'python' {{args}}
pyc cmd:
  {{p}}; {{_uvr}} 'python' '-c' '{{cmd}}'
pym *args:
  {{p}}; {{_uvr}} 'python' '-m' {{args}}
_uvr := 'uv run'

#? Common tasks

pyright:
  {{p}}; {{_uvr}} pyright
pytest:
  {{p}}; {{_uvr}} pytest
ruff:
  {{p}}; {{_uvr}} ruff check .
pre-commit *args:
  {{p}}; {{_uvr}} pre-commit run --verbose {{args}}

# Build wheel, compile binary, change its icon, and sign it
build:
  {{p}}; {{_uvr}} 'buildsign'
