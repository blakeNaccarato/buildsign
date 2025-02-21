from contextlib import chdir, contextmanager, nullcontext
from io import BytesIO
from os import environ
from pathlib import Path
from platform import system
from shlex import split
from shutil import copy
from subprocess import run
from zipfile import ZipFile

from httpx import Client

from buildsign.models import const


def get_pyapp():
    with Client(follow_redirects=True) as client:
        response = client.get(
            f"https://github.com/ofek/pyapp/releases/download/v{const.pyapp_version}/source.zip",
            timeout=30.0,
        )
        response.raise_for_status()
    with ZipFile(BytesIO(response.content)) as zip_file:
        zip_file.extractall(const.pyapp_checkpoint_root)
    (Path("pyapp") / ".cargo" / "config.toml").unlink(missing_ok=True)
    copy(const.cargo_config, const.pyapp / ".cargo" / "config.toml")


def build(package: str, path: Path | None = None, out_dir: Path | None = None):
    environ["UV_PREVIEW"] = "1"
    with chdir(path) if path else nullcontext():
        run(
            args=[
                "uv",
                "build",
                "--package",
                package,
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


def compile(package: str, version: str, path: Path):  # noqa: A001
    pyapp = path / "pyapp"
    with (
        chdir(pyapp),
        environment(
            PYAPP_EXPOSE_ALL_COMMANDS="1",
            PYAPP_PYTHON_VERSION=const.python_version,
            PYAPP_PROJECT_NAME=package,
            PYAPP_UV_ENABLED="1",
            PYAPP_UV_VERSION=const.uv_version,
            PYAPP_PROJECT_PATH=(
                path / "dist" / f"{package}-{version}-py3-none-any.whl"
            ).as_posix(),
        ),
    ):
        run(args=split("cargo build --release"), check=True)
    binary = path / "dist" / f"{package}.exe"
    if binary.exists():
        binary.unlink()
    (pyapp / "target/release/pyapp.exe").rename(binary)
    run(args=[binary, "self", "remove"], check=True)


def change_icon(package: str, path: Path | None = None):
    path = path or Path.cwd()
    binary = path / "dist" / f"{package}.exe"
    proj_icon = (
        _icon
        if (_icon := path / "data" / f"{package}.ico").exists()
        else const.default_icon
    )
    run(args=["rcedit", binary, "--set-icon", proj_icon], check=True)


def sign(package: str, account: str, profile: str, path: Path | None = None):
    binary = (path or Path.cwd()) / "dist" / f"{package}.exe"
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
                    f"az{'.cmd' if system() == 'Windows' else ''}",
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
