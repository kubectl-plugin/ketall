#!/usr/bin/env bash

# Copyright 2019 Cornelius Weig
# Copyright 2024 The kubectl-plugin Authors
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

set -euo pipefail

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if ! [[ -x "${DIR}/release-notes" ]]; then
  echo >&2 'Installing release-notes'
  relnotes_dir="$(mktemp -d)"
  trap 'rm -rf -- ${relnotes_dir}' EXIT

  cd "$relnotes_dir"
  go mod init foo
  GOBIN="${DIR}" go get github.com/kubectl-plugin/release-notes@v0.1.0
  cd -
fi

# you can pass your github token with --token here if you run out of requests
"${DIR}/release-notes" kubectl-plugin ketall

echo
echo "Thanks to all the contributors for this release: "
git log "$(git describe --tags --abbrev=0)".. --format="%aN" --reverse | sort --unique | sed 's:^:- :'
echo
