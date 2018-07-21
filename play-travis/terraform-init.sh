#!/usr/bin/env bash

GENERIC_FUNCTIONS=$(pwd)/config-scripts/generic-functions

if [ ! -r "${GENERIC_FUNCTIONS}" ]; then
  logger --tag ${SCRIPT_NAME} --stderr --id=$$ -p user.err "Can't find ${GENERIC_FUNCTIONS} file. Abort."
  exit 2
fi

source "${GENERIC_FUNCTIONS}"


for DIR in terraform/{,stage,prod};do
    exec_cmd "cp ${DIR}/terraform.tfvars{.example,}" "Copy ${DIR}/terraform.tfvars.example to ${DIR}/terraform.tfvars"
    echo "Initialize terrafrom in the ${DIR}"
    docker_terraform "${DIR}" init -backend=false
done
