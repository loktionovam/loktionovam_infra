#!/usr/bin/env bash

GENERIC_FUNCTIONS=generic-functions
SCRIPT_NAME=$(basename $0)

APP_NAME=reddit
APP_USER=appuser
APP_USER_HOME=$(getent passwd "${APP_USER}" | cut -d: -f6)
APP_GIT_URI="https://github.com/express42/${APP_NAME}.git"
APP_GIT_BRANCH=monolith
#Actually we need parse the config/deploy.rb to get puma bind address and port
APP_BIND_ADDRESS=0.0.0.0
APP_BIND_PORT=9292
UTILITIES_LIST="git curl"
PACKAGE_CACHE_UPDATED=false
WEB_SERVER_LAUNCH_RETRIES=3

if [ ! -r "${GENERIC_FUNCTIONS}" ]; then
  logger --tag ${SCRIPT_NAME} --stderr --id=$$ -p user.err "Can't find ${GENERIC_FUNCTIONS} file. Abort."
  exit 2
fi

source "${GENERIC_FUNCTIONS}"
obtain_lock "$@"

for UTILITY in ${UTILITIES_LIST}; do
  if ! is_package_installed "${UTILITY}"; then
    if [ "${PACKAGE_CACHE_UPDATED}" = false ]; then
      exec_cmd "sudo apt-get update" "Update package cache"
      PACKAGE_CACHE_UPDATED=true
    fi
    exec_cmd "sudo apt-get install --yes ${UTILITY}" "Install ${UTILITY} client"
  fi
done

exec_cmd "cd ${APP_USER_HOME}" "Enter to ${APP_USER} home directory"

if [ -d "${APP_NAME}" ]; then
  msg_info "Looks like application directory already exists, so skip clone and try to checkout to ${APP_GIT_BRANCH} and pull changes"
  exec_cmd "cd ${APP_NAME}" "Enter to ${APP_NAME} application directory"
  exec_cmd "sudo -u ${APP_USER} git checkout ${APP_GIT_BRANCH}" "Checkout to ${APP_GIT_BRANCH}"
  exec_cmd "sudo -u ${APP_USER} git pull" "Fetch and integrate changes from ${APP_GIT_URI}"
else
  exec_cmd "sudo -u ${APP_USER} git clone --branch ${APP_GIT_BRANCH} ${APP_GIT_URI}" \
            "Clone application ${APP_NAME} from ${APP_GIT_URI} and checkout to ${APP_GIT_BRANCH} branch"
  exec_cmd "cd ${APP_NAME}" "Enter to ${APP_NAME} application directory"
fi

exec_cmd "sudo -u ${APP_USER} bundle install" "Install the gems specified by the Gemfile"

while [ "${WEB_SERVER_LAUNCH_RETRIES}" -gt 0 ]; do
  if simple_http_check "http://${APP_BIND_ADDRESS}:${APP_BIND_PORT}"; then
    msg_info "Looks like http server launched on ${APP_BIND_ADDRESS}:${APP_BIND_PORT}"
    break
  else
    exec_cmd "sudo -u ${APP_USER} puma --daemon" "Start puma server in daemon mode on ${APP_BIND_ADDRESS}:${APP_BIND_PORT}"
    ((WEB_SERVER_LAUNCH_RETRIES--))
    sleep 5
  fi
done
