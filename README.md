# Running Eventum in Docker

## Initial setup

build `eventum` image
```
$ docker build -t eventum .
```

start the services using docker-compose

```
$ docker-composer up -d
```


## Upgrading

```
$ docker-compose exec eventum bin/upgrade.php
* Your database is already up-to-date. Version 58
```

## Volumes

```
$ docker volume ls
DRIVER              VOLUME NAME
local               eventum_code-3.1.4
local               eventum_config
local               eventum_mysql
```
