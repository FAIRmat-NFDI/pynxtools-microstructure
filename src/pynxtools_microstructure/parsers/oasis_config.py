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
"""Load deployment-specific quantities."""

import pathlib

import flatdict as fd
import yaml
from pynxtools_em.concepts.mapping_functors_pint import add_specific_metadata_pint
from pynxtools_em.utils.get_checksum import get_sha256_of_file_content

from pynxtools_microstructure.configurations.oasis_eln_config_cfg import (
    OASISCFG_MICROSTRUCTURE_CITATION_TO_NEXUS,
    OASISCFG_MICROSTRUCTURE_PROJECT_TO_NEXUS,
)
from pynxtools_microstructure.utils.custom_logging import logger


class NxMicrostructureNomadOasisConfigParser:
    """Parse deployment specific configuration."""

    def __init__(self, file_path: str, entry_id: int, verbose: bool = False):
        if pathlib.Path(file_path).name.endswith(
            (".oasis.specific.yaml", ".oasis.specific.yml")
        ):
            self.file_path: str = file_path
            self.entry_id: int = entry_id if entry_id > 0 else 1
            self.verbose: bool = verbose
            self.flat_metadata = fd.FlatDict({}, "/")
            self.supported: bool = False
            self.check_if_supported()
            if not self.supported:
                logger.debug(
                    f"Parser {self.__class__.__name__} finds no content in {file_path} that it supports"
                )
        else:
            logger.warning(
                f"Parser {self.__class__.__name__} needs oasis.specific.yaml file"
            )

    def check_if_supported(self):
        self.supported = False
        try:
            with open(self.file_path, encoding="utf-8") as stream:
                self.flat_metadata = fd.FlatDict(yaml.safe_load(stream), "/")
                if self.verbose:
                    for key, val in self.flat_metadata.items():
                        logger.info(f"key: {key}, val: {val}")
                self.supported = True
        except (OSError, FileNotFoundError):
            logger.warning(f"File {self.file_path} not found")
            return

    def parse(self, template: dict) -> dict:
        """Copy data from configuration applying mapping functors."""
        if self.supported:
            with open(self.file_path, "rb", 0) as fp:
                self.file_path_sha256 = get_sha256_of_file_content(fp)
            logger.info(
                f"Parsing {self.file_path} NOMAD Oasis/config with SHA256 {self.file_path_sha256} ..."
            )
            self.parse_example(template)
        return template

    def parse_example(self, template: dict) -> dict:
        """Copy data from example-specific section into template."""
        # customized entryID/experiment_description field
        composed_description: list[str] = []
        # TODO other cases possible, e.g. AI summaries

        src: str = "citation"
        if src in self.flat_metadata:
            if isinstance(self.flat_metadata[src], list):
                if (
                    all(isinstance(entry, dict) for entry in self.flat_metadata[src])
                    is True
                ):
                    # custom schema delivers a list of dictionaries...
                    cite_id: int = 1
                    for cite_dict in self.flat_metadata[src]:
                        if len(cite_dict) == 0:
                            continue
                        identifier: list[int] = [self.entry_id, cite_id]
                        add_specific_metadata_pint(
                            OASISCFG_MICROSTRUCTURE_CITATION_TO_NEXUS,
                            cite_dict,
                            identifier,
                            template,
                        )
                        cite_id += 1

                        for field_name in [
                            "title",
                            "author",
                            "doi",
                        ]:  # , "description"]:
                            if field_name in cite_dict:
                                composed_description.append(
                                    f"{cite_dict[field_name]}, "
                                )
                        break  # assume first reference is always to the dataset
                        # do not add further references

        identifier = [self.entry_id]
        add_specific_metadata_pint(
            OASISCFG_MICROSTRUCTURE_PROJECT_TO_NEXUS,
            self.flat_metadata,
            identifier,
            template,
        )

        if len(composed_description) > 0:
            message = "\n".join(composed_description).strip()
            template[f"/ENTRY[entry{self.entry_id}]/experiment_description"] = (
                message[:-1] if message.endswith(",") else message
            )

        if "user" in self.flat_metadata:
            user_id = 1
            for user_dict in self.flat_metadata["user"]:
                if "name" in user_dict:
                    template[
                        f"/ENTRY[entry{self.entry_id}]/userID[user{user_id}]/name"
                    ] = user_dict["name"]
                    user_id += 1

        # content from OpenAlex, a simple example
        # e.g. publication date as start_time when no other qualified pieces of information are available
        if "start_time" in self.flat_metadata:
            if self.flat_metadata["start_time"] != "":
                template[f"/ENTRY[entry{self.entry_id}]/start_time"] = (
                    self.flat_metadata["start_time"]
                )

        return template
