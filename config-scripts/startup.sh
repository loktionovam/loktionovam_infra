#! /bin/bash
#Very simple bootstrap script
GIT_REPO_URL=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/git_repo_url -H "Metadata-Flavor: Google")
GIT_REPO_BRANCH=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/git_repo_branch -H "Metadata-Flavor: Google")
SCRIPTS_LIST="install_ruby.sh install_mongodb.sh deploy.sh"

apt-get update
apt-get install --yes git
git clone --no-checkout --branch "${GIT_REPO_BRANCH}" --depth 1 "${GIT_REPO_URL}" startup

pushd startup || exit
git checkout HEAD config-scripts/generic-functions
for SCRIPT in ${SCRIPTS_LIST}; do
  git checkout HEAD config-scripts/"${SCRIPT}"
  config-scripts/"${SCRIPT}"
done
popd
