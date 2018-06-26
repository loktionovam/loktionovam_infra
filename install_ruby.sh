#!/usr/bin/env bash

GENERIC_FUNCTIONS=generic-functions
SCRIPT_NAME=$(basename $0)

RUBY_PACKAGES='ruby-full ruby-bundler build-essential'

if [ ! -r "${GENERIC_FUNCTIONS}" ]; then
  logger --tag ${SCRIPT_NAME} --stderr --id=$$ -p user.err "Can't find ${GENERIC_FUNCTIONS} file. Abort."
  exit 2
fi

source "${GENERIC_FUNCTIONS}"
obtain_lock "$@"

exec_cmd "sudo apt-get update" "Update package cache"

exec_cmd "sudo apt-get install --yes ${RUBY_PACKAGES}" "Install ruby related packages"
echo "Installed ruby version: $(ruby --version)"
echo "Installed bundler version: $(bundler --version)"
