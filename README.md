# loktionovam_infra
loktionovam Infra repository

**Build status**

master:
[![Build Status](https://travis-ci.com/Otus-DevOps-2018-05/loktionovam_infra.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-05/loktionovam_infra)

ansible-3:
[![Build Status](https://travis-ci.com/Otus-DevOps-2018-05/loktionovam_infra.svg?branch=ansible-3)](https://travis-ci.com/Otus-DevOps-2018-05/loktionovam_infra)

## Подключение через ssh к инстансам в GCP через bastion хост
### Начальные данные
* bastion
 * Пользователь: appuser
 * External IP: 35.206.144.27
 * Internal IP: 10.132.0.2
* someinternalhost
  * Пользователь: appuser
  * Internal IP: 10.132.0.3

На **bastion** имя **someinternalhost** разрешается в IP адрес
```bash
$ host  someinternalhost
someinternalhost.c.infra-207406.internal has address 10.132.0.3
```
### Для ssh версии 7.3 и выше
В новых версиях ssh для этих целей существует опция **ProxyJump** (ключ -J)
```bash
ssh -V
OpenSSH_7.6p1 Ubuntu-4, OpenSSL 1.0.2n  7 Dec 2017
```
Пример подключения из командной строки
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

### Для ssh более старых версий
В старых версиях ssh опции **ProxyJump** нет, но можно использовать опцию **ProxyCommand** и команда для подключения к **someinternalhost** будет выглядеть так:
```bash
ssh  -o 'ProxyCommand ssh appuser@35.206.144.27 -W %h:%p' appuser@someinternalhost
```
### Настройка ~/.ssh/config
Чтобы каждый раз при подключении к **someinternalhost** не указывать параметры **bastion** хоста, можно модифицировать **~/.ssh/config**
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
Проверка подключения через alias **someinternalhost**
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
## Подключение к инстансам в GCP через VPN

На **bastion** установлен и настроен pritunl VPN сервер. Для подключения к VPN нужно импортировать конфигурационный файл **cloud-bastion.ovpn** в OpenVPN клиент.

bastion_IP = 35.206.144.27
someinternalhost_IP = 10.132.0.3

## Управление GCP через gcloud

testapp_IP = 104.199.102.152
testapp_port = 9292  

Автоматическое создание инстанса тестового приложения **reddit-app** с использованием startup script
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
Создание правила файерволла для доступа к puma server
```bash
gcloud compute firewall-rules create default-puma-server --allow tcp:9292 --target-tags puma-server
```
## Сборка образов VM при помощи packer
Чтобы собрать образ VM нужно переименовать файл **packer/variables.json.example** и настроить в нем переменные **gcp_project_id**, **gcp_source_image_family**
```bash
mv packer/variables.json{.example,}
```
После этого образ **reddit-base** можно собрать командами
```bash
cd packer && packer validate -var-file=variables.json ubuntu16.json && packer build -var-file=variables.json  ubuntu16.json
```
и аналогично **reddit-full**
```bash
cd packer && packer validate -var-file=variables.json immutable.json && packer build -var-file=variables.json  immutable.json
```
после этого, создать и запустить инстанс можно скриптом **create-reddit-vm.sh** (по-умолчанию используется образ **reddit-full**)
```bash
config-scripts/create-reddit-vm.sh
```
чтобы использовать другой образ его нужно указать через ключ командной строки, например **-i reddit-base**
```bash
config-scripts/create-reddit-vm.sh -i reddit-base
...
config-scripts/create-reddit-vm.sh -h
Usage: create-reddit-vm.sh [-n INSTANCE_NAME] [-i IMAGE_FAMILY]
```

## Практика IaC с использованием Terraform

При использовании IaC есть проблема - больше нельзя вносить изменения в инфраструктуру вручную, т.е. IaC используется или всегда или никогда. Например, пусть мы добавили ssh ключи в метаданные проекта через terraform

```
ssh-keys = "appuser1:${chomp(file(var.public_key_path))}"
```

затем применили изменения, добавили еще несколько пользователей

```
    ssh-keys = <<EOF
appuser1:${chomp(file(var.public_key_path))}
appuser2:${chomp(file(var.public_key_path))}
appuser3:${chomp(file(var.public_key_path))}EOF
```

и опять применили изменения. После этого мы можем узнать, как со временем менялась инфраструктура, кто, когда и с какой целью вносил в нее изменения (это можно отследить через git, и файлы terraform.tfstate, terraform.tfstate.backup).

Если теперь мы внесем изменения вручную, например, добавив ssh ключ для пользователя appuser_web через веб-интерфейс GCP, то эти изменения нигде не будут отражены и при выполении команды

```bash
terraform apply
```

будут потеряны.

### Настройка HTTP балансировщика для пары хостов reddit-app, reddit-app2

После добавления reddit-app2 и настройки http балансировщика через terraform есть проблема, которая заключается в том, что приложение reddit-app это statefull приложение, т.е. у него есть состояние (мы храним его в mongodb), которое балансировка не учитывает. В этом легко убедиться, если создать статью и сравнить БД на reddit-app и reddit-app2:

```json
reddit-app:~# mongo
MongoDB shell version: 3.2.20
connecting to: test
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

т.е. пользователь будет получать разный ответ в зависимости от того, на какой бэкенд он попал. Решение - убрать mongodb с app серверов и решать проблемы балансировки и доступности для app серверов (stateless) и БД серверов (statefull) раздельно. Для БД в общем случае это будет репликация для решения проблем с производительностью чтения и отказоустойчивостью, и шардирование для решения проблем с производительностью записи.

Количество app серверов настраивается переменной count (по-умолчанию она равна 1) в файле **terraform.tfvars** Например, если задать

```
count = 3
```

то будет созадно 3 инстанса **reddit-app-001, reddit-app-002, reddit-app-003**

При этом после выполнения команды

```bash
terraform apply
```

будут выведены ip адреса каждого инстанса и ip адрес loadbalancer

```
app_external_ip = [
    reddit-app-001-ip-address-here,
    reddit-app-002-ip-address-here,
    reddit-app-003-ip-address-here
]
lb_app_external_ip = loadbalancer-ip-address-here
```

## Homework-7: Terraform: ресурсы, модули, окружения и работа в команде

#### 7.1 Что было сделано

Основные задания:
- Отключен loadbalancer из homework-6
- В packer созданы отдельные образы для db и app серверов соответственно
- Монолитная конфигурация terraform разбита на модули **app, db, vpc**
- В terraform созданы окружения для **stage** и **prod**

Задания со *:
- Созданы бакеты для хранения, в которые перемещены **prod** и **stage** terraform state files
- В конфигурацию **app** модуля terraform добавлено развертывание reddit приложения. Добавлен ключ для включения/выключения развертывания приложения

### 7.2 Как запустить проект

Исходное состояние: установлены terraform (проверено на версии **v0.11.7**), packer (проверено на версии **1.2.4**) с доступом к GCP

Создать образы reddit-app, reddit-db через packer, предварительно настроив **variables.json**
```bash
cd packer
cp variables.json{.example,}
#configure variables.json here
packer build -var-file=variables.json db.json
packer build -var-file=variables.json app.json
cd -
```

Создать бакеты для хранения state файла terraform, предварительно настроив **terraform.tfvars**
```bash
cd terraform
cp terraform.tfvars{.example,}
#configure terraform.tfvars here
terraform init
terraform apply -auto-approve
```

Создать prod/stage окружение, например для stage выполнить (при этом, для **prod** нужно задать переменную **source_ranges** для доступа по ssh):
```bash
cd stage/
cp terraform.tfvars{.example,}
#configure terraform.tfvars here
terraform init
terraform apply -auto-approve
```

### 7.3 Как проверить

В terraform/stage (или terraform/prod) выполнить

```bash
terraform output
```

будут выведены переменные **app_external_ip**, **db_external_ip**, при этом по адресу http://app_external_ip:9292 будет доступно приложение.

## Homework-8: Управление конфигурацией. Основные DevOps инструменты. Знакомство с Ansible

#### 8.1 Что было сделано

Основные задания:
- Установка и знакомство с базовыми функциями ansible
- Написание простых плейбуков

Задания со *:
- Создание inventory в формате json

### 8.2 Как запустить проект

Развернуть stage через terraform (см. **7.2 Как запустить проект**), после чего перейти в каталог ansible и запустить плейбук, клонирующий репозиторий reddit на app сервер

```bash
cd ansible
ansible-playbook clone.yml
```

Повторный запуск плейбука идемпотентен, т.е. повторно клонироваться репозиторий не будет (changed=0)

```bash
ansible-playbook clone.yml
...
appserver                  : ok=2    changed=0    unreachable=0    failed=0
```

Но если удалить склонированный репозиторий

```bash
ansible app -m command -a 'rm -rf ~/reddit'
 [WARNING]: Consider using file module with state=absent rather than running rm

appserver | SUCCESS | rc=0 >>
```

то исполнение плейбука склонирует репозиторий заново (changed=1)

```bash
ansible-playbook clone.yml
...
appserver                  : ok=2    changed=1    unreachable=0    failed=0
```

Для запуска ansible с использованием inventory в формате **json** нужен инвентори-скрипт, который в самом простом случае при вызове с ключом **--list** должен выводить хосты в json формате. Например, если у нас уже есть inventory.json, то передать его ansible можно таким скриптом **inventory_json**

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

Чтобы не указывать **inventory_json**, его можно добавить в **ansible.cfg**

```ini
inventory =./inventory_json,./inventory
```

### 8.3 Как проверить

После выполнения плейбука **clone.yml** можно проверить, что репозиторий действительно склонировался, например командой

```bash
ansible appserver -m command  -a "git log -1 chdir=/home/appuser/reddit"
```

## Homework-9: Деплой и управление конфигурацией с Ansible


### 9.1 Что было сделано

Основные задания:

- Создание плейбуков ansible для конфигурирования и деплоя reddit приложения (**site.yml, db.yml, app.yml, deploy.yml**)
- Создание плейбуков ansible (**packer_db.yml, packer_app.yml**), их использование в packer

Задания со *:

- Исследование возможности использования dynamic inventory в GCP через contrib модуль ansible (gce.py) и terraform state file
- Настройка dynamic inventory (выбран и используется **gce.py**). Дополнительно написаны ansible плейбуки для конфигурирования dynamic inventory  (**terraform_dynamic_inventory_setup.yml, gce_dynamic_inventory_setup.yml**)

### 9.2 Как запустить проект

Предварительные действия: развернуть stage (см. **7.2 Как запустить проект**)

#### 9.2.1 Настройка динамического inventory через gce.py (основной способ, используется в плейбуках раздела 9.2.3)

**Преимущества**: поставляется вместе с ansible; собирает больше данных, чем terraform-inventory; проще в настройке

**Недостатки**: это inventory только для GCE

Нужно создать сервисный аккаунт в GCE, скачать credential file в формате json и указать к нему путь во время исполнения **gce_dynamic_inventory_setup.yml**

```bash
cd ansible
ansible-playbook gce_dynamic_inventory_setup.yml
Enter path to GCE service account pem file [credentials/gce-service-account.json]:
```

Посмотреть хосты динамического inventory через gce.py можно так:

```bash
sudo apt-get install jq
./inventory_gce/gce.py --list | jq .
```

#### 9.2.2 Настройка динамического inventory через terraform-inventory

**Преимущества**: через terraform можно делать динамический inventory не только GCE, но и остльных провайдеров; возможно, более высокая производительность, т.к. state файл с данными уже существует (это предположение требует проверки)

**Недостатки**: текущий релиз (v0.7-pre Sep 22, 2016) не поддерживает terraform remote state file, как следствие, нужно компилировать; собирает меньше данных, чем gce.py; не очень понятно, что у него с поддержкой и комьюнити

Чтобы автоматически настроить динамический inventory через terraform, нужно выполнить:

```bash
cd ansible
ansible-playbook --ask-sudo-pass terraform_dynamic_inventory_setup.yml
```

Посмотреть хосты динамического inventory через terraform можно так (перед запуском, предполагается, что инфраструктура развернута через terraform):

```bash
sudo apt-get install jq
TF_STATE=../terraform/stage/ ./inventory_terraform/terraform-inventory --list | jq .
```

#### 9.2.3 Конфигурация и деплой приложения

Выполняем **9.2.1 Настройка динамического inventory через gce.py**

```bash
cd ansible
ansible-playbook site.yml
```

### 9.3 Как проверить проект

Описано в **7.3 Как проверить**

## Homework-10: Ansible - работа с ролями и окружениями

### 10.1 Что было сделано

Основные задания:

- Плейбуки (app.yml, db.yml, gce_dynamic_inventory_setup.yml, terraform_dynamic_inventory_setup.yml) переписаны с использованией ролей

- Созданы окружения stage, prod

- Добавлен users.yml плейбук с использованием ansible vault

- Добавлена сторонная роль jdauphant.nginx конфигурирующая nginx как прокси-сервер;

Задания со *:

- Настроено динамическое инвентори для окружений stage и prod

Задания с **:

- Настроен travis ci для запуска packer validate, terraform validate, tflint, ansible-lint. В README.md добавлен бейдж со статусом билда

### 10.2 Как запустить проект

Предварительные действия: развернуть stage (см. **7.2 Как запустить проект**)

- Установить в рабочее окружение gce.py или terrafom inventory для динамического инвентори (плейбуки app.yml, db.yml, deploy.yml поддерживают оба варианта через ad-hoc группы в ansible)

```bash
cd ansible
pip install -r requirements.txt
ansible-playbook playbooks/gce_dynamic_inventory_setup.yml
```

- Для работы nginx прокси установить комьюнити-роль jdauphant.nginx

```bash
ansible-galaxy install -r environments/stage/requirements.yml
```

- Настроить vault создав файл vault.key (используется в плейбуке users.yml)

```bash
echo "some_secret_for_ansible_vault" > ansible/vault.key
```

- Запустить развертывание reddit приложения

```bash
cd ansible
ansible-playbook playbooks/site.yml
```

### 10.3 Как проверить проект

- В README.md должен стоять бэйдж **build passing**

- В terraform/stage (или terraform/prod) выполнить

```bash
terraform output
```

будут выведены переменные **app_external_ip**, **db_external_ip**, при этом по адресу http://app_external_ip будет доступно приложение.
