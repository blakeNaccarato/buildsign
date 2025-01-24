"""Say hello."""

# /// script
# version = "0.0.0"
# requires-python = "==3.12.*"
# dependencies = ["cappa==0.26.4"]
# ///

from shlex import split
from subprocess import CREATE_NEW_CONSOLE, run

from cappa.base import command, invoke

SCRIPT = """
Set-Item -Path 'Function:/prompt' -Value { '> ' }
$Host.UI.RawUI.WindowTitle = '👋 hello'
function hello {[CmdletBinding(PositionalBinding = $False)] Param([Parameter(ValueFromPipeline, ValueFromRemainingArguments)][string[]]$Run) Process { uv run --script "hello.py" $Run } }
hello --help
"""


@command
class Hello:
    """Say hello."""

    name: str = "you"
    """Subject of the greeting."""
    shout: bool = False
    """Shout the greeting."""
    interactive: bool = False
    """Interactive."""

    def __call__(self):  # noqa: D102
        if self.interactive:
            run(  # noqa: S603
                split(f'powershell -NoExit -Command "{"; ".join(SCRIPT.split("\n"))}"'),
                check=False,
                creationflags=CREATE_NEW_CONSOLE,
            )
        else:
            print(f"Hello, {self.name}{'!' if self.shout else '.'}")  # noqa: T201


def main():  # noqa: D103
    invoke(Hello)


if __name__ == "__main__":
    main()
