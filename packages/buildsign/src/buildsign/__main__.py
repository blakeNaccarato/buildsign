from contextlib import chdir
from shutil import copytree, rmtree
from subprocess import run

from cappa.base import command, invoke

from buildsign.config import const


def just(*args: str):
    run(
        args=[
            const.just.as_posix(),
            "--one",
            "--justfile",
            const.justfile.as_posix(),
            *args,
        ],
        check=True,
    )


@command
class CLI:
    """CLI."""

    def __call__(self):
        just("build")
        if const.cache.build.exists():
            rmtree(const.cache.build)
        copytree(const.pyapp, const.cache.build)
        if const.cache.dist.exists():
            rmtree(const.cache.dist)
        copytree("dist", const.cache.dist)
        with chdir(const.cache.root):
            just("compile")
            just("change-icon")
            just("sign", const.sign_account, const.sign_profile)


def main():
    invoke(CLI)


if __name__ == "__main__":
    main()
