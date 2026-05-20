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

import os
from time import perf_counter_ns
from typing import Any

import numpy as np
from pynxtools import logger
from pynxtools.dataconverter.readers.base.reader import BaseReader
from pynxtools_em.utils.default_config import SEPARATOR
from pynxtools_em.utils.nx_atom_types import NxEmAtomTypesResolver
from pynxtools_em.utils.nx_default_plots import NxEmDefaultPlotResolver

from pynxtools_microstructure.parsers.nxs_mtex import NxEmNxsMtexParser


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
        tic = perf_counter_ns()
        template.clear()

        entry_id = 1

        parser = NxEmNxsMtexParser(file_paths[0], entry_id)
        parser.parse(template)

        nxplt = NxEmDefaultPlotResolver()
        nxplt.priority_select(template, entry_id)

        sample = NxEmAtomTypesResolver(entry_id)
        sample.identify_atom_types(template)

        debugging = False
        if debugging:
            logger.debug(
                "Reporting state of template before passing to HDF5 writing..."
            )
            for keyword, value in sorted(template.items()):
                logger.info(f"{keyword}{SEPARATOR}{type(value)}{SEPARATOR}{value}")

        logger.debug("Forward instantiated template to the NXS writer...")
        toc = perf_counter_ns()
        trg = f"/ENTRY[entry{entry_id}]/profiling/template_filling_elapsed_time"
        template[f"{trg}"] = np.float64((toc - tic) / 1.0e9)
        template[f"{trg}/@units"] = "s"

        return template


READER = MICROSTRUCTUREReader
