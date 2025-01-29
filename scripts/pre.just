# Script preamble
pre := '''
  # ? Error-handling
  $ErrorActionPreference = 'Stop'
  $PSNativeCommandUseErrorActionPreference = $True
  $ErrorView = 'NormalView'

  # ? Fix leaky UTF-8 encoding settings on Windows
  if ($IsWindows) {
      # ? Now PowerShell pipes will be UTF-8. Note that fixing it from Control Panel and
      # ? system-wide has buggy downsides.
      # ? See: https://github.com/PowerShell/PowerShell/issues/7233#issuecomment-640243647
      $OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.Encoding]::UTF8
  }
'''
