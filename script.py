"""Script."""

# /// script
# version = "0.0.0"
# requires-python = "==3.11.*"
# dependencies = [
#     "cappa==0.26.4",
# ]
# ///

from cappa.base import command, invoke


@command
class Hello:
    """Say hello."""

    name: str = "you"
    """Subject of the greeting."""

    def __call__(self):  # noqa: D102
        print(f"\n\tHello, {self.name}!\n")  # noqa: T201


def main():  # noqa: D103
    invoke(Hello)  # pyright: ignore[reportArgumentType]


if __name__ == "__main__":
    main()
