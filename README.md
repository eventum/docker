# Running Eventum in Docker

## Initial setup

build `eventum` image
```
docker build -t eventum .
```

start the services using docker-compose

```
docker-composer up -d
docker-compose exec eventum bin/upgrade.php
```

Open eventum: http://eventum.127.0.0.1.xip.io:8088/list.php


## Upgrading

```
docker-compose exec eventum bin/upgrade.php
* Your database is already up-to-date. Version 58
```

## Volumes

```
docker volume ls
DRIVER              VOLUME NAME
local               eventum_code-3.3.2
local               eventum_config
local               eventum_mysql
```
