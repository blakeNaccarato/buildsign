from shlex import split
from subprocess import run

from cappa.base import command, invoke

import hello
from hello import encode_powershell_script, windows_client_double_clicked


@command
class Hello:
    """Say hello."""

    name: str = "you"
    """Subject of the greeting."""
    shout: bool = False
    """Shout the greeting."""

    def __call__(self):
        print(f"Hello, {self.name}{'!' if self.shout else '.'}")  # noqa: T201


def windows_client_run_interactive():
    """Run the package interactively on Windows."""
    run(
        args=[
            *split("powershell -NoExit -EncodedCommand"),
            encode_powershell_script(f"""
                $Env:PATH = "$(Get-Location);$Env:PATH"
                {hello.__name__} --help
            """),
        ],
        check=True,
    )


def main():
    if windows_client_double_clicked():
        windows_client_run_interactive()
    else:
        invoke(Hello)


if __name__ == "__main__":
    main()
