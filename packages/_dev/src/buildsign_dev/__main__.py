"""Command-line interface."""

from dataclasses import dataclass

from cappa.base import command, invoke
from cappa.subcommand import Subcommands

from buildsign_dev import SyncEnvironmentVariables


@command(invoke="buildsign_dev.tools.add_change")
class AddChange:
    """Add change."""


@command(invoke="buildsign_dev.tools.get_actions")
class GetActions:
    """Get actions used by this repository."""


@command(invoke="buildsign_dev.tools.sync_local_dev_configs")
class SyncLocalDevConfigs:
    """Synchronize local dev configs."""


@command(invoke="buildsign_dev.tools.elevate_pyright_warnings")
class ElevatePyrightWarnings:
    """Elevate Pyright warnings to errors."""


@dataclass
class BoilercvDev:
    """Dev tools."""

    commands: Subcommands[
        SyncEnvironmentVariables
        | AddChange
        | GetActions
        | SyncLocalDevConfigs
        | ElevatePyrightWarnings
    ]


def main():
    """CLI entry-point."""
    invoke(BoilercvDev)


if __name__ == "__main__":
    main()
