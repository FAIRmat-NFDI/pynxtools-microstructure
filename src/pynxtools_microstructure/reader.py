#
# Copyright The NOMAD Authors.
#
# This file is part of NOMAD. See https://nomad-lab.eu for further info.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import logging
import os
from time import perf_counter_ns
from typing import Any

import numpy as np
from pynxtools.dataconverter.readers.base.reader import BaseReader
from pynxtools_em.utils.default_config import SEPARATOR
from pynxtools_em.utils.nx_atom_types import NxEmAtomTypesResolver
from pynxtools_em.utils.nx_default_plots import NxEmDefaultPlotResolver

from pynxtools_microstructure import get_pynxtools_microstructure_version
from pynxtools_microstructure.parsers.nxs_mtex import NxEmNxsMtexParser
from pynxtools_microstructure.parsers.oasis_config import (
    NxMicrostructureNomadOasisConfigParser,
)

logger = logging.getLogger("pynxtools-microstructure")


class MICROSTRUCTUREReader(BaseReader):
    """Reader for MICROSTRUCTURE."""

    supported_nxdls = ["NXem"]

    def read(
        self,
        template: dict | None = None,
        file_paths: tuple[str] | None = None,
        objects: tuple[Any] | None = None,
    ):
        """
        Read method to prepare the template.
        """
        logger.info(os.getcwd())
        tic: int = perf_counter_ns()
        template.clear()

        entry_id: int = 1

        # simple I/O logic, always the first of a mime_type and only one per mime_type
        io_logic: dict[str, str] = {}
        for mime_type in [".mtex.h5", ".oasis.specific.yaml"]:
            for file_path in file_paths:
                if file_path.endswith(mime_type):
                    if mime_type not in io_logic:
                        io_logic[mime_type] = file_path
                        break

        if ".mtex.h5" in io_logic and io_logic[".mtex.h5"] != "":
            mtex_hfive = NxEmNxsMtexParser(io_logic[".mtex.h5"], entry_id)
            mtex_hfive.parse(template)

            if (
                ".oasis.specific.yaml" in io_logic
                and io_logic[".oasis.specific.yaml"] != ""
            ):
                eln = NxMicrostructureNomadOasisConfigParser(
                    io_logic[".oasis.specific.yaml"], entry_id
                )
                eln.parse(template, io_logic[".mtex.h5"])

        nxplt = NxEmDefaultPlotResolver()
        nxplt.priority_select(template, entry_id)

        atom_types = NxEmAtomTypesResolver(entry_id)
        atom_types.identify_atom_types(template)

        debugging = False
        if debugging:
            logger.debug(
                "Reporting state of template before passing to HDF5 writing..."
            )
            for keyword, value in sorted(template.items()):
                logger.info(f"{keyword}{SEPARATOR}{type(value)}{SEPARATOR}{value}")

        logger.debug("Forward instantiated template to the NXS writer...")
        toc: int = perf_counter_ns()
        trg: str = (
            f"/ENTRY[entry{entry_id}]/profiling/CS_PROFILING_EVENT[event_pynxtools]"
        )
        template[f"{trg}/PROGRAM[program1]/program"] = "pynxtools-microstructure"
        template[f"{trg}/PROGRAM[program1]/program/@version"] = (
            f"{get_pynxtools_microstructure_version()}"
        )
        template[f"{trg}/template_filling_time"] = np.float64((toc - tic) / 1.0e9)
        template[f"{trg}/template_filling_time/@units"] = "s"

        return template


READER = MICROSTRUCTUREReader
