from cappa.base import command, invoke


@command
class CLI:
    """CLI."""

    def __call__(self):
        print("CLI")  # noqa: T201


def main():
    invoke(CLI)


if __name__ == "__main__":
    main()
