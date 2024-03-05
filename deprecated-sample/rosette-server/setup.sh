# Copyright 2023 Basis Technology Corporation.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash
BASE_DIR="$( cd "$( dirname "$0" )" && pwd )"
source ${BASE_DIR}/scripts/utils.sh

# comment out all selected languages
comment_out_languages "${BASE_DIR}"
info "Please uncomment the language models in ${LANGUAGE_FILE} that you would like to install."
info "\tThese are the languages you are licensed for and are listed in the rosette-license.xml file."
echo ""
create_endpoint_file "${BASE_DIR}"
info "Created ${ENDPOINT_FILE}. Please select some endpoints to install by uncommenting the desired endpoints."
