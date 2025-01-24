"""Script."""

# /// script
# version = "0.0.0"
# requires-python = "==3.11.*"
# dependencies = [
#     "cappa==0.26.4",
# ]
# ///

from __future__ import annotations

from cappa.base import command, parse


def hello(args: Hello):
    """Say hello."""
    print(f"\n\tHello, {args.name}!\n")  # noqa: T201


@command
class Hello:
    """Say hello."""

    name: str = "you"
    """Subject of the greeting."""


def main():  # noqa: D103
    hello(parse(Hello))


if __name__ == "__main__":
    main()
