#!/bin/sh
set -e
# delta_plugin convert signpost-fast-travel.yaml
tes3conv signpost-fast-travel.json signpost-fast-travel.omwaddon
delta_plugin convert PB_SignpostsRetextured.yaml
delta_plugin convert PB_SignpostsRetexturedTR.yaml
