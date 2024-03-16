#!/usr/bin/env bash
set -euo pipefail

#
# This script builds the project website. It downloads soupault as needed and
# then runs it, the built website can be found at: web/build
#

this_dir=$(realpath "$(dirname "${0}")")
cd "${this_dir}"

soupault_version=4.6.0
soupault_pkg=soupault-${soupault_version}-linux-x86_64.tar.gz
soupault_path=./soupault-${soupault_version}-linux-x86_64

shas=https://github.com/PataphysicalSociety/soupault/releases/download/${soupault_version}/sha256sums
spdl=https://github.com/PataphysicalSociety/soupault/releases/download/${soupault_version}/${soupault_pkg}

if ! [ -f ${soupault_path}/soupault ]; then
    wget ${shas}
    wget ${spdl}
    tar xf ${soupault_pkg}
    grep linux sha256sums | sha256sum -c -
fi

cp ../README.md site/readme.md
echo "Releases without a download link can be downloaded as a dev build from the link above." > site/changelog.md
grep -v "## Signpost Fast Travel" ../CHANGELOG.md >> site/changelog.md
echo '<div class="center"><a href="/img/signpost-fast-travel.gif"><img src="/img/signpost-fast-travel.gif" title="A short gif of the mod in action" /></a></div>' > site/index.md
echo '<div class="center"><a href="/img/signpost-fast-travel-menu.png"><img src="/img/signpost-fast-travel-menu.png" title="The travel menu" /></a></div>' >> site/index.md
grep -v "# Signpost Fast Travel" ../README.md >> site/index.md

PATH=${soupault_path}:$PATH soupault "$@"
