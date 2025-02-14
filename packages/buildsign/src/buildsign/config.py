from dataclasses import dataclass, field
from importlib import resources
from importlib.metadata import version
from pathlib import Path

from platformdirs import user_cache_path

import buildsign

__all__ = ["const"]

NAME = buildsign.__name__
DIST = "dist"
PYAPP = "pyapp"
CARGO_LOCK = "Cargo.lock"
SIGNER = "blake-naccarato"


@dataclass
class Constants:
    name: str = buildsign.__name__

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
