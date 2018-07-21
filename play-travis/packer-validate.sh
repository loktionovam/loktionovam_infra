#!/usr/bin/env bash

GENERIC_FUNCTIONS=$(pwd)/config-scripts/generic-functions

if [ ! -r "${GENERIC_FUNCTIONS}" ]; then
  logger --tag ${SCRIPT_NAME} --stderr --id=$$ -p user.err "Can't find ${GENERIC_FUNCTIONS} file. Abort."
  exit 2
fi

source "${GENERIC_FUNCTIONS}"

for TEMPLATE in packer/*.json;do
    docker_packer packer/variables.json.example "${TEMPLATE}"
done
