#!/usr/bin/env bash
GENERIC_FUNCTIONS=$(dirname "$0")/generic-functions
SCRIPT_NAME=$(basename $0)
INSTANCE_NAME="reddit-app-$(date +%s)"
IMAGE_FAMILY="reddit-full"

if [ ! -r "${GENERIC_FUNCTIONS}" ]; then
  logger --tag ${SCRIPT_NAME} --stderr --id=$$ -p user.err "Can't find ${GENERIC_FUNCTIONS} file. Abort."
  exit 2
fi

source "${GENERIC_FUNCTIONS}"

function show_help {
  echo "Usage: ${SCRIPT_NAME} [-n INSTANCE_NAME] [-i IMAGE_FAMILY]"
}

while getopts ":n:i:h" OPTION
do
  case $OPTION in
    n)INSTANCE_NAME="${OPTARG}"
      ;;
    i)IMAGE_FAMILY="${OPTARG}"
      ;;
    h) show_help
      exit
      ;;
  esac
done


exec_cmd "gcloud compute instances create ${INSTANCE_NAME} --image-family ${IMAGE_FAMILY} --machine-type=g1-small --tags puma-server --restart-on-failure" \
        "Create GCP instance ${INSTANCE_NAME} from ${IMAGE_FAMILY} image"
