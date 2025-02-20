# buildsign

An example of signed executable Python binaries using PyApp with caching and Azure Trusted Signing. The generated program is a simple CLI that generates variations on `"Hello, <name>."` as a proof-of-concept. See build recipes in `justfile`, a work in progress, but currently local building and signing has been implemented. This experiment will inform a project template and GitHub Action that facilitates this for arbitrary Python projects.

## Contributing

```Shell
# On Windows.
powershell -ExecutionPolicy ByPass -Command 'irm https://astral.sh/uv/0.5.29/install.ps1 | iex'
uvx --from 'rust-just@1.39.0' just --explain inst all
```

```Shell
# On macOS and Linux.
curl -LsSf https://astral.sh/uv/0.5.29/install.sh | sh
uvx --from 'rust-just@1.39.0' just --explain inst all
```

## Attributions

Binary artifacts built with [PyApp](https://ofek.dev/pyapp) using the `cargo build --release` approach with `pyapp/Cargo.lock` and other files from the project's source distribution checked in for caching, licensed under [MIT](https://spdx.org/licenses/MIT.html) per [PyApp's license statement](https://github.com/ofek/pyapp#license). The icon for distributable binaries is an emoji designed by [OpenMoji](https://openmoji.org/) – the open-source emoji and icon project, licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/#).
