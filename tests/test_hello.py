"""Tests."""

from cappa.testing import CommandRunner
from hello.__main__ import Hello


def test_main():
    """Script runs."""
    CommandRunner(Hello)
