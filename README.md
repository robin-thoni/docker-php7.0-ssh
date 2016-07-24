Docker for php 7.0 with ssh
==================================

Why?
----

This docker file allows you to run php 7.0 scripts on any server configuration. This is useful if you have to run tests or composer commands that require php 7.0. See docker help for more information.

Usage
-----

Build the image:
```shell
git clone https://git.rthoni.com/robin.thoni/docker-php7.0-ssh
cd docker-php7.0-ssh
docker build -t php7.0-ssh .
```

Run a container:
```shell
docker run -d -v /path/to/my/php/application/:/data/ -p 2200:22 --name=container-my-php-application-ssh php7.0-ssh
```

Connect to the container:
```shell
ssh root@127.0.0.1 -o Port=2200 # password is 'toor' (without quotes)
```
