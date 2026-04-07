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
from nomad.config.models.north import NORTHTool
from nomad.config.models.plugins import NorthToolEntryPoint

tool = NORTHTool(
    short_description="NORTH tool for pynxtools plugin pynxtools-microstructure.",
    image="ghcr.io/fairmat-nfdi/pynxtools-microstructure/jupyter:latest",
    description="NORTH tool for pynxtools plugin pynxtools-microstructure.",
    external_mounts=[],
    file_extensions=["ipynb", "nxs"],
    icon="logo/jupyter.svg",
    image_pull_policy="Always",
    default_url="/lab",
    maintainer=[{"email": "fairmat@physik.hu-berlin.de", "name": "The NOMAD Authors"}],
    mount_path="/home/jovyan",
    path_prefix="lab/tree",
    privileged=False,
    with_path=True,
    display_name="microstructure",
)

microstructure = NorthToolEntryPoint(
    id_url_safe="pynxtools_microstructure_microstructure", north_tool=tool
)
