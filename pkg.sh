#!/bin/sh
set -e

modname=signpost-fast-travel
file_name=$modname.zip

cat > version.txt <<EOF
Mod version: $(git describe --tags)
EOF

zip --must-match --recurse-paths ${file_name} \
    CHANGELOG.md \
    LICENSE \
    README.md \
    $modname.omwaddon \
    $modname.omwscripts \
    PB_SignpostsRetextured.omwaddon \
    PB_SignpostsRetexturedTR.omwaddon \
    icons \
    l10n \
    meshes \
    scripts \
    textures \
    version.txt \
    --exclude=scripts/momw_sft_scriptbridge.mwscript

sha256sum ${file_name} > ${file_name}.sha256sum.txt
sha512sum ${file_name} > ${file_name}.sha512sum.txt
