"""Say hello."""

# /// script
# version = "0.0.0"
# requires-python = "==3.12.*"
# dependencies = ["cappa==0.26.4"]
# ///

from pathlib import Path
from shlex import split
from subprocess import run
from textwrap import dedent

from cappa.base import command, invoke


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
            fun = dedent(f"""
            function hello {{
                [CmdletBinding(PositionalBinding = $False)]
                Param([Parameter(ValueFromPipeline, ValueFromRemainingArguments)][string[]]$Run)
                Process {{ Get-Content {Path(__file__)} | uv run --script - $Run }}
            }}
            """)
            script = dedent(f"""
            Set-Item -Path 'Function:/prompt' -Value {{ '> ' }}
            $Host.UI.RawUI.WindowTitle = '👋 hello'
            {" ".join(fun.split("\n"))}
            hello --help
            """)
            run(  # noqa: S603
                split(f'pwsh -NoExit -Command "{"; ".join(script.split("\n"))}"'),
                check=True,
            )
        else:
            print(f"Hello, {self.name}{'!' if self.shout else '.'}")  # noqa: T201


def main():  # noqa: D103
    invoke(Hello)


if __name__ == "__main__":
    main()
