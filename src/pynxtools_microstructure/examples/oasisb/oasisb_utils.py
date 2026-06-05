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


from pycountry import countries


def get_project_id(project_name: str) -> str:
    """Convert integer project_name ids like 1, 2, 3, ..., to three-digit format with prefix D for dataset or A for article."""
    if 1 <= len(project_name) <= 3:
        return f"{'0' * (3 - len(project_name))}{project_name}"
    return ""


def is_valid_alpha3(code: str) -> bool:
    try:
        return countries.get(alpha_3=code.upper()) is not None
    except KeyError:
        return False


CSV_HEADER_FOR_HASH_FILE = "file_path:archive_path;byte_size;unix_mtime;sha256sum"
