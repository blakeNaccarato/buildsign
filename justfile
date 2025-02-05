#? Imports
import 'scripts/pre.just'

#? Settings
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

# TODO: Make recipe that gets/unzips pyapp sources into `./pyapp`

start_process := 'Start-Process -NoNewWindow -Wait'
write_progress := 'Write-Host -ForegroundColor Yellow'
write_complete := 'Write-Host -ForegroundColor Green'
sep := '"..."'

# Build wheel, build and sign binary
[script]
build \
  name = 'hello' \
  code_sigining_account_name = 'blake-naccarato' \
  code_sigining_certificate_profile_name = 'blake-naccarato' \
  code_signing_correlation_id = 'blake-naccarato-laptop' \
  code_signing_digest_alg = 'SHA256' \
  $PYAPP_EXPOSE_ALL_COMMANDS = '1' \
  $PYAPP_PYTHON_VERSION = '3.12' \
  $PYAPP_UV_ENABLED = '1' \
  $PYAPP_UV_VERSION = '0.5.24' \
:
  #? Run preamble
  {{pre}}

  @("INPUTS", {{sep}}) | {{ write_progress }}

  #? Map Just vars to script vars
  $Name = $Env:PYAPP_PROJECT_NAME = '{{name}}'
  $CodeSigningAccountName = '{{code_sigining_account_name}}'
  $CodeSigningCertificateProfileName = '{{code_sigining_certificate_profile_name}}'
  $CodeSigningCorrelationId = '{{code_signing_correlation_id}}'
  $CodeSigningDigestAlg = '{{code_signing_digest_alg}}'
  @("Code signing:"
    "  Account name: $CodeSigningAccountName"
    "  Profile name: $CodeSigningCertificateProfileName"
    "  Correlation ID: $CodeSigningCorrelationId"
    {{sep}}) | {{ write_progress }}

  #? Utils
  $Hacker = 'C:/Program Files (x86)/Resource Hacker/ResourceHacker.exe'
  $SignTool = 'C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/signtool.exe'
  @("Utils:"
    "  Hacker: $Hacker"
    "  SignTool: $SignTool"
    {{sep}}) | {{ write_progress }}

  #? Dirs
  $InvokeDir = "$( Get-Item '{{invocation_dir()}}' )"
  $JustDir = "$( Get-Item '{{justfile_dir()}}' )"
  $PyAppDir = "$( Get-Item $JustDir/pyapp )"
  @("Dirs:"
    "  InvokeDir: $InvokeDir"
    "  JustDir: $JustDir"
    "  PyAppDir: $PyAppDir"
    {{sep}}) | {{ write_progress }}

  #? Sources
  if (Test-Path "$InvokeDir/$Name.ico") { $Icon = "$InvokeDir/$Name.ico" }
  else { $Icon = "$JustDir/default.ico" }
  $Icon = "$( Get-Item $Icon )"
  @("Sources:"
    "  Icon: $Icon"
    {{sep}}) | {{ write_progress }}

  #? Build wheel
  @("", "BUILDING WHEEL", {{sep}}) | {{ write_progress }}
  $DistDir = "$InvokeDir/dist"
  if ( Test-Path $DistDir ) { Remove-Item -Recurse -Force $DistDir }
  $DistDir = New-Item -ItemType Directory -Path $DistDir
  try {
    Set-Location $InvokeDir
    uv build
  }
  finally { Set-Location $JustDir }
  $Env:PYAPP_PROJECT_PATH = "$(Get-ChildItem $DistDir -Filter *.whl)"
  @("BUILT WHEEL") | {{write_complete}}

  #? Compile binary
  @("", "COMPILING BINARY", {{sep}}
    "PyApp Environment variables:", ""
    Get-ChildItem 'Env:' | ? { $_.Name -like 'PYAPP_*' } | Out-String |
      % { $_.Split("`n") } | ? { $_ -match '\S' } | % { "  $_" }
    {{sep}}) | {{ write_progress }}
  $PyApp = "$PyAppDir/target/release/pyapp.exe"
  if (Test-Path $PyApp) { Remove-Item $PyApp }
  try {
    Set-Location $PyAppDir
    cargo build --release
  }
  finally {
    Set-Location $JustDir
    git restore "$PyAppDir/Cargo.lock"
  }
  $PyApp = "$(Get-Item $PyApp)"
  @("COMPILED BINARY") | {{write_complete}}

  #? Change icon
  @("", "CHANGING ICON", {{sep}}) | {{ write_progress }}
  $App = "$DistDir/$Name.exe"
  {{start_process}} $Hacker @(
    '-open', $PyApp
    '-save', $App                  #? Save as named binary
    '-action', 'addoverwrite'      #? Add resources, overwriting existing
    '-res', $Icon                  #? Icon resource to add
    '-mask', 'ICONGROUP,MAINICON'  #? Add to an icon group and make it the main icon
  )
  Remove-Item $PyApp
  $App = "$(Get-Item $App)"
  @(""
    "ICON CHANGED",
    "  App: $App"
    "  Icon: $Icon"
  ) | {{write_complete}}

  #? Sign
  @("", "SIGNING", {{sep}}) | {{ write_progress }}
  {{start_process}} $SignTool @(
    'sign'                                       #? Sign the binary
    '/v'                                         #? Verbose output
    '/debug'                                     #? Display debugging information
    '/fd', $CodeSigningDigestAlg                 #? File digest algorithm
    '/td', $CodeSigningDigestAlg                 #? Timestamp digest algorithm
    '/tr', 'http://timestamp.acs.microsoft.com'  #? Timestamp server
    '/dlib', "$Env:USERPROFILE/.nuget/packages/microsoft.trusted.signing.client/1.0.60/bin/x64/Azure.CodeSigning.Dlib.dll"
    '/dmdf', $(                                  #? Metadata
      @{
        Endpoint               = 'https://wus3.codesigning.azure.net'
        CodeSigningAccountName = $CodeSigningAccountName
        CertificateProfileName = $CodeSigningCertificateProfileName
        CorrelationId          = $CodeSigningCorrelationId
        ExcludeCredentials     = @(
          'AzureCliCredential'
          'AzureDeveloperCliCredential'
          'AzurePowerShellCredential'
          'EnvironmentCredential'
          'ManagedIdentityCredential'
          'SharedTokenCacheCredential'
          'VisualStudioCodeCredential'
          'VisualStudioCredential'
          'WorkloadIdentityCredential'
        )
      } | ConvertTo-Json | Set-Content ( $File = New-TemporaryFile )
      "$File"
    )
    $App  #? App to sign
  )
  @("SIGNED", "  App: $App" ) | {{write_complete}}
