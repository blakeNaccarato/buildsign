from base64 import b64encode
from os import environ
from platform import system
from subprocess import run
from sys import argv
from textwrap import dedent


def pwsh_args(script: str, *args: str) -> list[str | bytes]:
    """Return args suitable for running the text of a PowerShell script.

    Encodes a PowerShell script to Base64 for passing to `-EncodedCommand`.
    """
    return [
        *["powershell.exe", "-NonInteractive", "-NoProfile"],
        *args,
        "-EncodedCommand",
        b64encode(
            bytearray(
                dedent("""\
                    Set-StrictMode -Version '3.0'
                    $ErrorActionPreference = 'Stop'
                    $PSNativeCommandUseErrorActionPreference = $True
                    $ErrorView = 'NormalView'
                    $OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.Encoding]::UTF8
                    """)
                + dedent(script),
                "utf-16-le",
            )
        ),
    ]


def windows_client_double_clicked():
    """Determine whether the Windows binary of this package was double-clicked."""
    if (
        system() != "Windows"
        or not environ.get("PYAPP")
        or len(argv.pop(0) if argv[0] == "-c" else argv) > 1
    ):
        return False
    pyapp_parent_process_name_indicating_windows_client_double_clicked = "explorer"
    return (
        run(
            args=pwsh_args("""\
                $PyAppParentDepth = 4
                function Get-ParentProcessId {
                  Param( $Id = $PID, $Depth = 1 )
                  if ( $Depth -le 0 ) { return $Id }
                  return Get-ParentProcessId -Depth ( $Depth - 1 ) (
                    Get-CimInstance -Class 'Win32_Process' -Filter "ProcessId = $Id" |
                      Select-Object -First 1 -ExpandProperty 'ParentProcessId'
                  )
                }
                try {
                  $Id = (
                    Get-ParentProcessId -Depth $PyAppParentDepth |
                      ForEach-Object -Process { Get-Process -Id $_ }
                  )
                }
                catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
                  return $null
                }
                $Id | Select-Object -ExpandProperty 'ProcessName'"""),
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
    ) == pyapp_parent_process_name_indicating_windows_client_double_clicked
