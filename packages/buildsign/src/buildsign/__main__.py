from contextlib import chdir, contextmanager, nullcontext
from io import BytesIO
from os import environ
from pathlib import Path
from platform import system
from shlex import split
from shutil import copy, copytree, rmtree
from subprocess import run
from zipfile import ZipFile

import httpx
from cappa.base import command, invoke

from buildsign.config import const


def get_pyapp_sources():
    with httpx.Client(follow_redirects=True) as client:
        response = client.get(
            f"https://github.com/ofek/pyapp/releases/download/v{const.pyapp_version}/source.zip",
            timeout=30.0,
        )
        response.raise_for_status()
    with ZipFile(BytesIO(response.content)) as zip_file:
        zip_file.extractall(const.pyapp_checkpoint_root)
    (Path("pyapp") / ".cargo" / "config.toml").unlink(missing_ok=True)
    copy(const.cargo_config, const.pyapp / ".cargo" / "config.toml")


def build(name: str, path: Path | None = None, out_dir: Path | None = None):
    environ["UV_PREVIEW"] = "1"
    with chdir(path) if path else nullcontext():
        run(
            args=[
                "uv",
                "build",
                "--package",
                name,
                *(["--out-dir", out_dir] if out_dir else []),
            ],
            check=True,
        )


@contextmanager
def environment(**kwds):
    orig_environ = dict(environ)
    try:
        environ.update(kwds)
        yield
    finally:
        environ.clear()
        environ.update(orig_environ)


def compile(name: str, version: str, path: Path):  # noqa: A001
    pyapp = path / "pyapp"
    with (
        chdir(pyapp),
        environment(
            PYAPP_EXPOSE_ALL_COMMANDS="1",
            PYAPP_PYTHON_VERSION=const.python_version,
            PYAPP_PROJECT_NAME=name,
            PYAPP_UV_ENABLED="1",
            PYAPP_UV_VERSION=const.uv_version,
            PYAPP_PROJECT_PATH=(
                path / "dist" / f"{name}-{version}-py3-none-any.whl"
            ).as_posix(),
        ),
    ):
        run(args=split("cargo build --release"), check=True)
    binary = path / "dist" / f"{name}.exe"
    if binary.exists():
        binary.unlink()
    (pyapp / "target/release/pyapp.exe").rename(binary)
    run(args=[binary, "self", "remove"], check=True)


def change_icon(name: str, path: Path | None = None):
    path = path or Path.cwd()
    binary = path / "dist" / f"{name}.exe"
    proj_icon = (
        _icon
        if (_icon := path / "data" / f"{name}.ico").exists()
        else const.default_icon
    )
    run(args=["rcedit", binary, "--set-icon", proj_icon], check=True)


def sign(name: str, account: str, profile: str, path: Path | None = None):
    binary = (path or Path.cwd()) / "dist" / f"{name}.exe"
    run(
        args=[
            "jsign",
            "--storetype",
            "TRUSTEDSIGNING",
            "--keystore",
            "wus3.codesigning.azure.net",
            "--alias",
            f"{account}/{profile}",
            "--storepass",
            run(
                args=[
                    *(
                        ["powershell.exe", "-NonInteractive", "-NoProfile", "-Command"]
                        if system() == "Windows"
                        else []
                    ),
                    "az",
                    "account",
                    "get-access-token",
                    "--resource",
                    "https://codesigning.azure.net",
                    "--query",
                    "accessToken",
                ],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip(),
            binary,
        ],
        check=True,
    )


@command
class CLI:
    """CLI."""

    def __call__(self):
        name = "hello"
        version = "0.0.0"
        build(name=name, out_dir=const.dist)
        const.cache.mkdir(exist_ok=True)
        if not const.pyapp_checkpoint.exists():
            get_pyapp_sources()
        if const.pyapp.exists():
            copy(const.cargo_lock_checkpoint, const.cargo_lock)
        else:
            copytree(const.pyapp_checkpoint, const.pyapp)
        compile(name=name, version=version, path=const.cache)
        rmtree(const.proj_dist, ignore_errors=True)
        copytree(const.dist, const.proj_dist)
        change_icon(name=name)
        sign(name=name, account=const.sign_account, profile=const.sign_profile)


def main():
    invoke(CLI)


if __name__ == "__main__":
    main()
