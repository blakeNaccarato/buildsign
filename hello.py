"""Say hello."""

# /// script
# version = "0.0.0"
# requires-python = "==3.12.*"
# dependencies = ["cappa==0.26.4"]
# ///

from shlex import split
from subprocess import run
from sys import argv

from cappa.base import command, invoke


@command
class Hello:
    """Say hello."""

    name: str = "you"
    """Subject of the greeting."""
    shout: bool = False
    """Shout the greeting."""

    def __call__(self):  # noqa: D102
        print(f"Hello, {self.name}{'!' if self.shout else '.'}")  # noqa: T201


def main():  # noqa: D103
    invoke(Hello)


def imain():  # noqa: D103
    run(check=True, args=[*split("uvx --from . hello"), *argv[1:]])


if __name__ == "__main__":
    main()
