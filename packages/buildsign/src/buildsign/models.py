from dataclasses import dataclass, field
from importlib import resources
from importlib.metadata import version
from pathlib import Path
from shutil import copy, copytree, rmtree
from typing import Annotated as Ann

from cappa.arg import Arg
from cappa.base import command
from cappa.subcommand import Subcommands
from platformdirs import user_cache_path

import buildsign

NAME = buildsign.__name__
DIST = "dist"
CARGO_LOCK = "Cargo.lock"
PYAPP = "pyapp"
SIGNER = "blake-naccarato"


@dataclass
class Constants:
    buildsign_version: str = field(default=version(NAME))
    pyapp_version: str = "0.26.0"
    python_version: str = "3.12"
    uv_version: str = "0.5.29"

    files: Path = Path(resources.files(buildsign))  # pyright: ignore[reportArgumentType]
    default_icon: Path = files / "default.ico"
    cargo_config: Path = files / "cargo-config.toml"

    sign_account: str = SIGNER
    sign_profile: str = SIGNER

    proj_dist: Path = Path(DIST)

    cache: Path = user_cache_path() / NAME
    pyapp_checkpoint_root: Path = cache / f"{PYAPP}-checkpoint"
    pyapp_checkpoint: Path = pyapp_checkpoint_root / f"{PYAPP}-v{pyapp_version}"
    cargo_lock_checkpoint: Path = pyapp_checkpoint / CARGO_LOCK
    dist: Path = cache / DIST
    pyapp: Path = cache / PYAPP
    cargo_lock: Path = pyapp / CARGO_LOCK


const = Constants()


@dataclass
class Versions:
    buildsign: str = field(default=version(NAME))
    pyapp: str = "0.26.0"
    python: str = "3.12"
    uv: str = "0.5.29"


@dataclass
class Package:
    name: str
    version: str


@dataclass
class Common:
    versions: Ann[Versions, Arg.destructured]
    package: Ann[Package, Arg.destructured]


@command(invoke="buildsign.get_pyapp")
class GetPyApp:
    version: str = const.pyapp_version
    root: Path = const.cache / "pyapp-checkpoint"


@command(invoke="buildsign.build")
class Build:
    common: Ann[Common, Arg.destructured]


@command(invoke="buildsign.compile")
class Compile:
    common: Ann[Common, Arg.destructured]


@command(invoke="buildsign.change_icon")
class ChangeIcon:
    common: Ann[Common, Arg.destructured]


@command(invoke="buildsign.sign")
class Sign:
    common: Ann[Common, Arg.destructured]


@dataclass
class CLI:
    """CLI."""

    command: Subcommands[GetPyApp | Build | Compile | ChangeIcon | Sign]

    def __call__(self):
        return
        from buildsign import build, change_icon, compile, get_pyapp, sign  # noqa: A004, I001, PLC0415

        name = "hello"
        version = "0.0.0"
        rmtree(const.dist, ignore_errors=True)
        build(package=name, out_dir=const.dist)
        const.cache.mkdir(exist_ok=True)
        if not const.pyapp_checkpoint.exists():
            get_pyapp()
        if const.pyapp.exists():
            copy(const.cargo_lock_checkpoint, const.cargo_lock)
        else:
            copytree(const.pyapp_checkpoint, const.pyapp)
        compile(package=name, version=version, path=const.cache)
        rmtree(const.proj_dist, ignore_errors=True)
        copytree(const.dist, const.proj_dist)
        change_icon(package=name)
        sign(package=name, account=const.sign_account, profile=const.sign_profile)
