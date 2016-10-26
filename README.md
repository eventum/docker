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
