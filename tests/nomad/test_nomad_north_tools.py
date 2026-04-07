"""Tests for the NOMAD NORTH tool."""

import pytest

try:
    import nomad  # noqa: F401
except ImportError:
    pytest.skip(
        "Skipping NOMAD NORTH tool tests because nomad-lab is not installed",
        allow_module_level=True,
    )


@pytest.mark.skip(reason="No functional north tool yet")
def test_importing_north_tool():
    from pynxtools_microstructure.nomad.north_tools import (
        microstructure,  # noqa: PLC0415
    )

    assert (
        microstructure.id_url_safe == "microstructure"
        or microstructure.id == "nomad-north-microstructure"
    ), "NORTHtool entry point has incorrect id or id_url_safe"
