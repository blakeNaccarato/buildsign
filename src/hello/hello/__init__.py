from base64 import b64encode
from os import environ
from platform import system
from subprocess import run
from sys import argv


def encode_powershell_script(script: str) -> bytes:
    """Encode a PowerShell script to Base64 for passing to `-EncodedCommand`."""
    return b64encode(bytearray(script, "utf-16-le"))


def windows_client_double_clicked():
    """Determine whether the Windows binary of this package was double-clicked."""
    if system() != "Windows" or not environ.get("PYAPP") or len(argv) > 1:
        return False
    script = """
        $PyAppParentDepth = 4
        function Get-ParentProcessId {
            Param($Id = $PID, $Depth = 1)
            if ($Depth -le 0) { return $Id }
            $CimArgs = @{
                Class  = 'Win32_Process'
                Filter = "ProcessId = $Id"
            }
            $ParentId = (Get-CimInstance @CimArgs)[0].ParentProcessId
            return Get-ParentProcessId -Id $ParentId -Depth ($Depth - 1)
        }
        (Get-Process -Id (Get-ParentProcessId -Depth $PyAppParentDepth)).ProcessName
    """
    return (
        run(
            args=["powershell", "-EncodedCommand", encode_powershell_script(script)],
            capture_output=True,
            text=True,
            check=True,
        )
    ).stdout.strip() == "explorer"
