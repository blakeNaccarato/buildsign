"""Tests."""

from cappa.testing import CommandRunner

from hello import Hello


def test_main():
    """Script runs."""
    CommandRunner(Hello)
