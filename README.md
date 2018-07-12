# loktionovam_infra
loktionovam Infra repository

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
