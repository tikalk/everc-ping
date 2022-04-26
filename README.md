# node.js ms on kubertnetes

## ⏳ Requirements

- [`docker`](https://docs.docker.com/get-docker/)
- [`docker-compose`](https://docs.docker.com/compose/)

Optional - yet recommanded:

## 🥅 Todays Goal's

Deploy a microservice architecture app using `docker-compose`

- redis
- api      (./src/api)
- consumer (./src/pinger)
- client   (./src/poller)

### Background on ping app

1. Use `redis` to store pings, using `redis:latest@sha256:a89cb097693dd354de598d279c304a1c73ee550fbfff6d9ee515568e0c749cfe` to ensure these LAB's function as expected altough `latest` should work ;)
1. To disable redis authentication Use `nodejs-ping` with tag `no-auth` or `latest@sha256:85d7474aabdd2d01802a9957c770ec157a478db71b7ce5f8d07d1e221cc39cba` see the `docker-compose-no-auth.yml`
1. Pinger & Poller are just 2 clients using `latest` tag should suffice.

In order to test you have everything `docker-compose build` will buid all images locally,
A functional a `docker-compose up` should build/pull the required images.

- See `Makefile` for details from running a local node.js ping app to running the `make dc-run` as presented in the following asciinema cast

[![asciicast](https://asciinema.org/a/BkFq5HGzKQr6TPnz8wWgin3Ep.svg)](https://asciinema.org/a/BkFq5HGzKQr6TPnz8wWgin3Ep)

---

⏭️ Running ping-app on kubernetes ...
