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
