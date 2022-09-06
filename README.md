# loktionovam_infra

loktionovam Infra repository

**Build status**

master:
[![Build Status](https://travis-ci.com/Otus-DevOps-2018-05/loktionovam_infra.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-05/loktionovam_infra)

ansible-4:
[![Build Status](https://travis-ci.com/Otus-DevOps-2018-05/loktionovam_infra.svg?branch=ansible-4)](https://travis-ci.com/Otus-DevOps-2018-05/loktionovam_infra)

db role(v.1.1.0):
[![Build Status](https://travis-ci.org/loktionovam/db.svg?branch=1.1.0)](https://travis-ci.org/loktionovam/db)


* [loktionovam_infra](#loktionovam_infra)
  * [SSH connect to GCP instances through a bastion host](#ssh-connect-to-gcp-instances-through-a-bastion-host)
    * [Connection parameters](#connection-parameters)
    * [ssh version 7.3 and newer](#ssh-version-73-and-newer)
    * [ssh version 7.2 and older](#ssh-version-72-and-older)
    * [Setup ~/.ssh/config](#setup-sshconfig)
  * [Connection to GCP instances through VPN](#connection-to-gcp-instances-through-vpn)
  * [Managing GCP via gcloud](#managing-gcp-via-gcloud)
  * [Building VM images by packer](#building-vm-images-by-packer)
  * [Practicing IaC and usage of Terraform](#practicing-iac-and-usage-of-terraform)
    * [Setup a HTTP loadbalancer for reddit-app, reddit-app2](#setup-a-http-loadbalancer-for-reddit-app-reddit-app2)
  * [Homework-7: Terraform: resources, modules, environments and teamwork](#homework-7-terraform-resources-modules-environments-and-teamwork)
      * [7.1 What was done](#71-what-was-done)
    * [7.2 How to start the project](#72-how-to-start-the-project)
    * [7.3 How to check the project](#73-how-to-check-the-project)
  * [Homework-8: Configuration management. The main DevOps tools. Introduction to Ansible](#homework-8-configuration-management-the-main-devops-tools-introduction-to-ansible)
      * [8.1 What was done](#81-what-was-done)
    * [8.2 How to start the project](#82-how-to-start-the-project)
    * [8.3 How-to check the project](#83-how-to-check-the-project)
  * [Homework-9: Deploy and configuration management by Ansible](#homework-9-deploy-and-configuration-management-by-ansible)
    * [9.1 What was done](#91-what-was-done)
    * [9.2 How-to start the project](#92-how-to-start-the-project)
      * [9.2.1 Setup the dynamic inventory via gce.py (this is the main way, used in the playbooks section 9.2.3)](#921-setup-the-dynamic-inventory-via-gcepy-this-is-the-main-way-used-in-the-playbooks-section-923)
      * [9.2.2 Setup the dynamic inventory via terraform-inventory](#922-setup-the-dynamic-inventory-via-terraform-inventory)
      * [9.2.3 Application configuration and deploy](#923-application-configuration-and-deploy)
    * [9.3 How to check the project](#93-how-to-check-the-project)
  * [Homework-10: Ansible - roles and environments](#homework-10-ansible---roles-and-environments)
    * [10.1 What was done](#101-what-was-done)
    * [10.2 How-to start the project](#102-how-to-start-the-project)
    * [10.3 How-to check the project](#103-how-to-check-the-project)
  * [Homework-11: Development and testing Ansible roles and playbooks](#homework-11-development-and-testing-ansible-roles-and-playbooks)
    * [11.1 What was done](#111-what-was-done)
    * [11.2 How-to start the project](#112-how-to-start-the-project)
      * [11.2.1 Ansible db role repository](#1121-ansible-db-role-repository)
      * [11.2.2 Integration db role with ansible galaxy](#1122-integration-db-role-with-ansible-galaxy)
      * [11.2.3 Start the dev environment](#1123-start-the-dev-environment)
    * [11.3 How-to check the project](#113-how-to-check-the-project)

## SSH connect to GCP instances through a bastion host

### Connection parameters

* bastion
* User: appuser
* External IP: 35.206.144.27
* Internal IP: 10.132.0.2
* someinternalhost
  * User: appuser
  * Internal IP: 10.132.0.3

At the **bastion** host the name **someinternalhost** is resolved to an IP address:

```bash
$ host  someinternalhost
someinternalhost.c.infra-207406.internal has address 10.132.0.3
```

### ssh version 7.3 and newer

In the new versions of ssh there is an option **ProxyJump** (`-J`) to connect to private infrastructure via a jump host:

```bash
ssh -V
OpenSSH_7.6p1 Ubuntu-4, OpenSSL 1.0.2n  7 Dec 2017
```

For example, here is a connection from CLI:

```bash
$ ssh -i ~/.ssh/appuser -J appuser@35.206.144.27 appuser@someinternalhost
Welcome to Ubuntu 16.04.4 LTS (GNU/Linux 4.13.0-1019-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  Get cloud support with Ubuntu Advantage Cloud Guest:
    http://www.ubuntu.com/business/services/cloud

0 packages can be updated.
0 updates are security updates.


Last login: Sat Jun 16 08:06:18 2018 from 10.132.0.2
appuser@someinternalhost:~$
```

### ssh version 7.2 and older

There aren't any ssh option **ProxyJump** but you can use an option named **ProxyCommand** so the command to connect to **someinternalhost**:

```bash
ssh  -o 'ProxyCommand ssh appuser@35.206.144.27 -W %h:%p' appuser@someinternalhost
```

### Setup ~/.ssh/config

If you don't want to manually provide the connection parameters of a **bastion** host every time you can modify **~/.ssh/config**

```bash
$ if ssh -J 2>&1 | grep "unknown option -- J" >/dev/null; then PROXY_COMMAND='ProxyCommand ssh appuser@bastion -W %h:%p'; else PROXY_COMMAND='ProxyJump %r@bastion'; fi
$ cat <<EOF>>~/.ssh/config

host bastion
HostName 35.206.144.27

host someinternalhost
  HostName someinternalhost
  User appuser
  ServerAliveInterval 30
${PROXY_COMMAND}
  IdentityFile ~/.ssh/appuser
EOF

```

Testing a connection with an alias **someinternalhost**

```bash
$ ssh someinternalhost
Welcome to Ubuntu 16.04.4 LTS (GNU/Linux 4.13.0-1019-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  Get cloud support with Ubuntu Advantage Cloud Guest:
    http://www.ubuntu.com/business/services/cloud

0 packages can be updated.
0 updates are security updates.


Last login: Sat Jun 16 08:24:37 2018 from 10.132.0.2
appuser@someinternalhost:~$
```

## Connection to GCP instances through VPN

**pritunl** vpn server is installed on the **bastion** host. To setup VPN connection import **cloud-bastion.ovpn** to an OpenVPN client.

bastion_IP = 35.206.144.27
someinternalhost_IP = 10.132.0.3

## Managing GCP via gcloud

testapp_IP = 104.199.102.152
testapp_port = 9292  

To create an instance of **reddit-app** by startup script:

```bash
export GIT_REPO_URL=https://github.com/Otus-DevOps-2018-05/loktionovam_infra.git
gcloud compute instances create reddit-app \
--boot-disk-size=10GB \
--image-family ubuntu-1604-lts \
--image-project=ubuntu-os-cloud \
--machine-type=g1-small \
--tags puma-server \
--restart-on-failure \
--metadata-from-file startup-script=config-scripts/startup.sh \
--metadata=git_repo_url="${GIT_REPO_URL}",git_repo_branch=$(git rev-parse --abbrev-ref HEAD)
```

To create a firewall rule to access to a puma server

```bash
gcloud compute firewall-rules create default-puma-server --allow tcp:9292 --target-tags puma-server
```

## Building VM images by packer

To build VM image rename **packer/variables.json.example** and setup **gcp_project_id**, **gcp_source_image_family** inside it:

```bash
mv packer/variables.json{.example,}
```

Run the building **reddit-base** image:

```bash
cd packer && packer validate -var-file=variables.json ubuntu16.json && packer build -var-file=variables.json  ubuntu16.json
```

and similarly to build **reddit-full**

```bash
cd packer && packer validate -var-file=variables.json immutable.json && packer build -var-file=variables.json  immutable.json
```

to create and start an instance execute **create-reddit-vm.sh** (by default it use **reddit-full** image)

```bash
config-scripts/create-reddit-vm.sh
```

to use another image (for example, **reddit-base**) use `-i` argument:

```bash
config-scripts/create-reddit-vm.sh -i reddit-base
...
config-scripts/create-reddit-vm.sh -h
Usage: create-reddit-vm.sh [-n INSTANCE_NAME] [-i IMAGE_FAMILY]
```

## Practicing IaC and usage of Terraform

There is a problem while you are use IaC approach - you can not manually change your infrastructure. For example, assume we added a ssh key to a project metadata via terraform

```
ssh-keys = "appuser1:${chomp(file(var.public_key_path))}"
```

apply the changes and added some other users

```
    ssh-keys = <<EOF
appuser1:${chomp(file(var.public_key_path))}
appuser2:${chomp(file(var.public_key_path))}
appuser3:${chomp(file(var.public_key_path))}EOF
```

and apply the changes again. After that we can track (git and terraform.tfstate, terraform.tfstate.backup) how our infrastructure had been changed during the time and who, when and why changed it.

Now if we manually change our infrastructure, for example, by adding a ssh key for appuser_web via GCP web-interface then these changes will never be shown during an execution:

```bash
terraform apply
```

and they will be lost.

### Setup a HTTP loadbalancer for reddit-app, reddit-app2

If you add reddit-app2 and setup a http loadbalancer via terraform there will be a problem because reddit-app is a statefull application, i.e. is has a state (it stores the state in a mongodb) and the loadbalancer knows nothing about this. It would be easy to verify if we create an article and compare the database state on  reddit-app  reddit-app2:

```json
reddit-app:~# mongo
MongoDB shell version: 3.2.20
connecting to: t
> db.adminCommand( { listDatabases: 1 } )
{
 "databases" : [
  {
   "name" : "local",
   "sizeOnDisk" : 65536,
   "empty" : false
  }
 ],
 "totalSize" : 65536,
 "ok" : 1
}
```

```json
reddit-app2:~# mongo
MongoDB shell version: 3.2.20
connecting to: test
> db.adminCommand( { listDatabases: 1 } )
{
 "databases" : [
  {
   "name" : "local",
   "sizeOnDisk" : 65536,
   "empty" : false
  },
  {
   "name" : "user_posts",
   "sizeOnDisk" : 65536,
   "empty" : false
  }
 ],
 "totalSize" : 131072,
 "ok" : 1
}
```

i.e. a user get a different answer and it depends on which backend answered to him. The solution is to move mongodb from the app servers and to solve the balancing problems for app servers (stateless) and database servers (statefull) separately. For the database servers it will be replication for read scaling/availability and sharding for write scaling.

The number of app servers is set up in `count` variable (by default 1) in **terraform.tfvars** For example this

```
count = 3
```

will create three instances **reddit-app-001, reddit-app-002, reddit-app-003**

to show app servers ip addresses and loadbalancer address execute:

```bash
terraform apply
```

```
app_external_ip = [
    reddit-app-001-ip-address-here,
    reddit-app-002-ip-address-here,
    reddit-app-003-ip-address-here
]
lb_app_external_ip = loadbalancer-ip-address-here
```

## Homework-7: Terraform: resources, modules, environments and teamwork

#### 7.1 What was done

Main tasks:
* disabled the loadbalancer from homework-6
* created db and app images
* the terraform monolith configuration was refactored and split to  **app, db, vpc** modules
* created **stage** and **prod** environments in terraform

Advanced tasks *:
* created S3 buckets where **prod** and **stage** terraform state files was placed
* to **app** terraform module was added deployment of reddit application. Added a switch to enable/disable the deployment of the application

### 7.2 How to start the project

Prerequisite: terraform (**v0.11.7**), packer (**1.2.4**) are installed

Create reddit-app, reddit-db images via the packer by set up **variables.json**

```bash
cd packer
cp variables.json{.example,}
#configure variables.json here
packer build -var-file=variables.json db.json
packer build -var-file=variables.json app.json
cd -
```

Create S3 bucket to store the terraform state file by set up **terraform.tfvars**

```bash
cd terraform
cp terraform.tfvars{.example,}
#configure terraform.tfvars here
terraform init
terraform apply -auto-approve
```

Create the prod/stage environments, for example to create `stage` execute (or to create **prod** setup **source_ranges** variable to grant a ssh access):

```bash
cd stage/
cp terraform.tfvars{.example,}
#configure terraform.tfvars here
terraform init
terraform apply -auto-approve
```

### 7.3 How to check the project

At the `terraform/stage` (or `terraform/prod`) execute:

```bash
terraform output
```

this command shows **app_external_ip**, **db_external_i** variables at the same time the application will be launched <http://app_external_ip:9292>.

## Homework-8: Configuration management. The main DevOps tools. Introduction to Ansible

#### 8.1 What was done

Main tasks:
* Installation ansible and introduction to the basic features
* Writing of simple playbooks

Advanced task *:
* Create an inventory in a json format

### 8.2 How to start the project

Deploy the stage environment via terraform (**7.2 How to start the project**), enter to ansible directory and start a playbook that will clone a reddit repository an app server

```bash
cd ansible
ansible-playbook clone.yml
```

The second running of the playbook is idempotent, i.e. the repository will not be cloned for the second time (changed=0)

```bash
ansible-playbook clone.yml
...
appserver                  : ok=2    changed=0    unreachable=0    failed=0
```

But if we delete the cloned repository

```bash
ansible app -m command -a 'rm -rf ~/reddit'
 [WARNING]: Consider using file module with state=absent rather than running rm

appserver | SUCCESS | rc=0 >>
```

the execution of the playbook will clone the repository one more time (changed=1)

```bash
ansible-playbook clone.yml
...
appserver                  : ok=2    changed=1    unreachable=0    failed=0
```

To run ansible with **json** inventory, an inventory script is needed, which in the simplest case (**--list** key) must print the hosts in the json format. For example, if we already have inventory.json we can pass it to ansible by this:

```bash
#!/usr/bin/env bash

if [ "$1" = "--list" ] ; then
    cat $(dirname "$0")/inventory.json
elif [ "$1" = "--host" ]; then
    echo "{}"
fi
```

```bash
ansible -i inventory_json all -m ping
```

You can add it to **ansible.cfg** to not write it in CLI command every time

```ini
inventory =./inventory_json,./inventory
```

### 8.3 How-to check the project

After playbook **clone.yml** was executed you can check that the repository was cloned

```bash
ansible appserver -m command  -a "git log -1 chdir=/home/appuser/reddit"
```

## Homework-9: Deploy and configuration management by Ansible

### 9.1 What was done

Main tasks:

* created ansible playbooks to configure and deploy the reddit application (**site.yml, db.yml, app.yml, deploy.yml**)
* created playbooks (**packer_db.yml, packer_app.yml**) for packer

Advanced tasks *:

* usage of a dynamic inventory in GCP by the ansible contrib module (gce.py) and the terraform state file
* setup the dynamic inventory (**gce.py** was chosen). Additionally  the ansible playbooks to configure dynamic inventory was written  (**terraform_dynamic_inventory_setup.yml, gce_dynamic_inventory_setup.yml**)

### 9.2 How-to start the project

Prerequisites: deploy the stage (**7.2 How-to start the project**)

#### 9.2.1 Setup the dynamic inventory via gce.py (this is the main way, used in the playbooks section 9.2.3)

**Pros**: out of the box with ansible; collect more data than terraform-inventory; easier to setup

**Cons**: this is the inventory only for GCE

We need to create a  GCE service account, download a credential file (in a json format) and setup the path to it while **gce_dynamic_inventory_setup.yml** execution

```bash
cd ansible
ansible-playbook gce_dynamic_inventory_setup.yml
Enter path to GCE service account pem file [credentials/gce-service-account.json]:
```

To list the host of the dynamic inventory via gce.py:

```bash
sudo apt-get install jq
./inventory_gce/gce.py --list | jq .
```

#### 9.2.2 Setup the dynamic inventory via terraform-inventory

**Pros**: not only GCE dynamic inventory, but the other provides too; perhaps faster execution because a state file with data already exists (need to check)

**Cons**: current release (v0.7-pre Sep 22, 2016) doesn't support terraform remote state file, as a consequence, we need to compile it; collect less data than gce.py; lack of support and community

To automatically setup dynamic inventory via terraform:

```bash
cd ansible
ansible-playbook --ask-sudo-pass terraform_dynamic_inventory_setup.yml
```

to list hosts from the dynamic inventory via terraform (we assume that an infrastructure is deployed by terraform):

```bash
sudo apt-get install jq
TF_STATE=../terraform/stage/ ./inventory_terraform/terraform-inventory --list | jq .
```

#### 9.2.3 Application configuration and deploy

Execute **9.2.1 Setup the dynamic inventory via gce.py**

```bash
cd ansible
ansible-playbook site.yml
```

### 9.3 How to check the project

Described in **7.3 How-to check the project**

## Homework-10: Ansible - roles and environments

### 10.1 What was done

Main tasks:

* The playbooks (app.yml, db.yml, gce_dynamic_inventory_setup.yml, terraform_dynamic_inventory_setup.yml) was refactored and roles was used

* The environments stage, prod was created

* Add users.yml playbook that use an ansible vault

* Added an external role named jdauphant.nginx that configures nginx as a proxy server;

Advanced task *:

* Setup the dynamic inventory for stage and  prod environments

Advanced task **:

* Setup travis ci to launch packer validate, terraform validate, tflint, ansible-lint. The badge with build status was added to README.md

### 10.2 How-to start the project

Prerequisites: deploy the stage (**7.2 How-to start the project**)

* Install gce.py or terrafom inventory for the dynamic inventory (the playbooks app.yml, db.yml, deploy.yml support the both ways via ansible ad-hoc groups)

```bash
cd ansible
pip install -r requirements.txt
ansible-playbook playbooks/gce_dynamic_inventory_setup.yml
```

* To setup a nginx reverse proxy install community role jdauphant.nginx

```bash
ansible-galaxy install -r environments/stage/requirements.yml
```

* Setup a vault by creating vault.key (used by users.yml playbook)

```bash
echo "some_secret_for_ansible_vault" > ansible/vault.key
```

* Deploy the reddit application

```bash
cd ansible
ansible-playbook playbooks/site.yml
```

### 10.3 How-to check the project

* В README.md should include **build passing** badge

* In the  `terraform/stage` (or  `terraform/prod`) execute:

```bash
terraform output
```

the variables **app_external_ip**, **db_external_ip** will be printed and the application will be here <http://app_external_ip>.

## Homework-11: Development and testing Ansible roles and playbooks

### 11.1 What was done

Main tasks:

* Local development with Vagrant - the configuration of appserver and dbserver was describe in Vagrantfile

* Added base.yml playbook to bootstrap the ansible on hosts where python is not installed

* db role was refactored to support Vagrant, added tasks config_mongo.yml, install_mongo.yml

* Added appserver and dbserver provisioners to a Vagrantfile

* Added db role tests (molecula and testinfra)

Advanced tasks *:

* Added dev environment, where a parametrization of appserver in Vagrant is set up

* db role moved to the separate repository named loktionovam/db, db role imported to ansible galaxy and included in requirements.yml (stage and prod environments)

* setup testing for db role (molecule/testinfra) in GCE via travis ci after push to the repository, added a build status badge to README.md, integrate travis ci builds with slack

### 11.2 How-to start the project

#### 11.2.1 Ansible db role repository

How to manually start test without travis

* Clone the repository

```bash
git clone git@github.com:loktionovam/db.git
cd db
```

* We assume that the ssh keys to connect to GCE instances already placed to ~/.ssh/google_compute_engine{,pub}

```bash
ssh-keygen -t rsa -f google_compute_engine -C 'travis' -q -N ''
```

* How to upload keys is described here <https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys>

* Genereate a service account

```bash
gcloud iam service-accounts create travis --display-name travis
```

* Create a secret file for the service account

```bash
gcloud iam service-accounts keys create ./credentials.json --iam-account travis@infra-207406.iam.gserviceaccount.com
```

Add the service account roles

```bash
gcloud projects add-iam-policy-binding infra-207406 --member serviceAccount:travis@infra-207406.iam.gserviceaccount.com --role roles/editor
```

**Notice1:**  roles/editor has too many privileges so perhaps it will be reasonable to set up a role with less privileges

* Start molecule tests in GCE (you need to replace `infra-some-project-id` by real project name)

```bash
export P_ID=infra-some-project-id
USER=travis GCE_SERVICE_ACCOUNT_EMAIL=travis@${P_ID}.iam.gserviceaccount.com GCE_CREDENTIALS_FILE=$(pwd)/credentials.json GCE_PROJECT_ID=${P_ID} molecule test
```

Set up integration with travis ci (**important!!!**: if you use a temporary repository (in examples it is trytravis-db-role)  you need to specify the repository name while the secret data encryption and also you need to temporary change the role name to trytravis-db-role in molecule playbook)

```bash
travis encrypt 'GCE_SERVICE_ACCOUNT_EMAIL=travis@infra-207406.iam.gserviceaccount.com' --repo loktionovam/trytravis-db-role
travis encrypt GCE_CREDENTIALS_FILE=\$TRAVIS_BUILD_DIR/credentials.json --repo loktionovam/trytravis-db-role
travis encrypt 'GCE_PROJECT_ID=infra-207406' --repo loktionovam/trytravis-db-role
travis login --org --repo loktionovam/trytravis-db-role
tar cvf secrets.tar credentials.json google_compute_engine
travis encrypt-file secrets.tar --repo loktionovam/trytravis-db-role --add
# check and fix .travis.yml - after encryption via travis encrypt the linter shows errors
molecule lint
```

After all the errors will be fixed through trytravis re-encrypt all the data but for the main project (repeat the previous steps but without key `--repo`)

Integration with slack

```bash
travis encrypt "devops-team-otus:some-secret-info" --add notifications.slack -r loktionovam/db
molecule lint
```

#### 11.2.2 Integration db role with ansible galaxy

* Sign up ansible galaxy

* Setup role metadata (**author, description, license, tags, platforms, company**) in meta/main.yml

```yaml
---
galaxy_info:
  author: Aleksandr Loktionov
  description: mongodb role
  company: none
  license: BSD
  min_ansible_version: 2.4
  platforms:
    - name: Ubuntu
      versions:
        - xenial
  galaxy_tags:
    - database
dependencies: []
```

* Import the role to ansible galaxy, fix linter errors

```bash
ansible-galaxy import loktionovam db
```

**Notice 1:** ansible galaxy web interface doesn't allow to import a role which name is shorter that two symbols. There aren't such limitations via cli.

**Примечание 2:** despite the ansible-galaxy import has a key role-name

```bash
ansible-galaxy import --help | grep -A 2 role-name=ROLE_NAME
  --role-name=ROLE_NAME
                        The name the role should have, if different than the
                        repo name

```

it didn't work, i.e. the role had been imported without any errors but it name was not changed (I don't know why is that because <https://github.com/ansible/ansible/commit/bd9ca5ef28dff4f788f92bc2068a5a490e7c9be9> this commit seems to solve the problem but it still doesn't work)

#### 11.2.3 Start the dev environment

Deploy the project in dev environment (appserver, dbserver)

```bash
cd ansible
ansible-galaxy install -r environments/dev/requirements.yml
vagrant up
```

Remove the dev environment

```bash
vagrant destroy
```

### 11.3 How-to check the project

* appserver, dbserver should be accessible by ssh

```bash
vagrant ssh appserver
vagrant ssh dbserver
```

* The reddit application works <http://10.10.10.20/>
