#!/usr/bin/env bash

GENERIC_FUNCTIONS=generic-functions
SCRIPT_NAME=$(basename $0)

DISTRO_NAME=$(lsb_release --id --short | tr '[:upper:]' '[:lower:]')
MONGODB_PACKAGES='mongodb-org'
MONGODB_VERSION=3.2

MONGODB_REPO_KEYSERVER='hkp://keyserver.ubuntu.com:80'
MONGODB_REPO_KEY='EA312927'

MONGODB_REPO_PROTOCOL='http'
MONGODB_REPO_ADDRESS='repo.mongodb.org'
MONGODB_REPO_URI="${MONGODB_REPO_PROTOCOL}://${MONGODB_REPO_ADDRESS}/apt/${DISTRO_NAME}"
MONGODB_REPO_CODENAME=$(lsb_release --codename --short)
MONGODB_REPO_SUITE="${MONGODB_REPO_CODENAME}/mongodb-org/${MONGODB_VERSION}"
MONGODB_REPO_COMPONENT='multiverse'
MONGODB_REPO="${MONGODB_REPO_URI} ${MONGODB_REPO_SUITE} ${MONGODB_REPO_COMPONENT}"
MONGODB_REPO_LIST_FILE="/etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list"

if [ ! -r "${GENERIC_FUNCTIONS}" ]; then
  logger --tag ${SCRIPT_NAME} --stderr --id=$$ -p user.err "Can't find ${GENERIC_FUNCTIONS} file. Abort."
  exit 2
fi

source "${GENERIC_FUNCTIONS}"
obtain_lock "$@"

#using add-apt-repository to enable repositories is a good idea, but now this utility does not support the-sources-list-file option
#so use is_repo_enabled, enable_repo functions
if ! is_repo_enabled "${MONGODB_REPO_URI} ${MONGODB_REPO_SUITE}/${MONGODB_REPO_COMPONENT}"; then
  exec_cmd "sudo apt-key adv --keyserver ${MONGODB_REPO_KEYSERVER} --recv ${MONGODB_REPO_KEY}" "Add key ${MONGODB_REPO_KEY} to the list of trusted keys"
  enable_repo "${MONGODB_REPO}" "${MONGODB_REPO_LIST_FILE}"
else
  msg_info "Looks like the repository ${MONGODB_REPO} already enabled."
fi

exec_cmd "sudo apt-get install --yes ${MONGODB_PACKAGES}" "Install mongodb related packages"
exec_cmd "sudo systemctl start mongod" "Start mongod service"
exec_cmd "sudo systemctl enable mongod" "Enable mongod unit file"

exec_cmd "systemctl status mongod" "Print mongod service status"
