"""Tests."""

from cappa.testing import CommandRunner

from script import Hello


def test_main():
    """Script runs."""
    CommandRunner(Hello)
