from dataclasses import dataclass, field
from importlib import metadata, resources
from importlib.metadata import version
from pathlib import Path
from sys import version_info

from platformdirs import user_cache_path
from uv import find_uv_bin

import buildsign

__all__ = ["const"]

NAME = buildsign.__name__


@dataclass
class Versions:
    self: str = field(default=version(NAME))
    just: str = field(default=version("rust-just"))
    pyapp: str = "0.26.0"
    python: str = f"{version_info.major}.{version_info.minor}"
    uv: str = field(default=version("uv"))


VERSIONS = Versions()


@dataclass
class Cache:
    root: Path = user_cache_path() / NAME
    dist: Path = root / "dist"
    build: Path = root / "pyapp"
    # TODO: Persist pyapp sources

    def __post_init__(self):
        self.root.mkdir(exist_ok=True)


@dataclass
class Constants:
    name: str = buildsign.__name__
    versions: Versions = field(default_factory=Versions)
    root: Path = Path(resources.files(buildsign))  # pyright: ignore[reportArgumentType]
    cache: Cache = field(default_factory=Cache)
    just: Path = field(
        default=Path(
            next(
                p
                for p in (metadata.files("rust-just") or [])
                if p.stem.endswith("just")
            ).locate()
        ).resolve()
    )
    uv: Path = field(default=Path(find_uv_bin()))
    justfile: Path = root / "justfile"
    pyapp: Path = root / "pyapp"
    scripts: Path = root / "scripts"
    sign_account: str = "blake-naccarato"
    sign_profile: str = sign_account


const = Constants()
